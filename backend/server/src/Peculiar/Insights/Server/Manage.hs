{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Server.Manage
  ( ManageServer (..)
  , ManageClient (..)
  , manage
  , jsonOnlyForManage
  ) where

import Control.Monad (unless)
import Data.Aeson (ToJSON, toJSON)
import Data.Int (Int64)
import Data.ProtoLens (defMessage)
import Data.ProtoLens.Field (HasField)
import Data.ProtoLens.Labels ()
import Data.Text qualified as T
import GHC.Generics (Generic, Generically (..))
import Lens.Family2 ((^.))
import Peculiar.Insights.Server.Api (storing)
import Peculiar.Insights.Server.Clock (Clock (..))
import Peculiar.Insights.Server.Db (Db (..), Disposition (..), Target (..), stateOf)
import Peculiar.Insights.Server.Env
import Peculiar.Insights.Server.Grafana (Grafana (..), Refusal (..), admit, describeRefusal, identityHeader)
import Peculiar.Insights.Server.Journal (Journal (..))
import Peculiar.Rpc qualified as Rpc
import Proto.Peculiar.Insights.V1.Manage

Rpc.deriveService ''Manage

data Triaged = Triaged
  { project :: T.Text
  , environment :: T.Text
  , issue :: Int64
  , state :: T.Text
  }
  deriving stock (Generic)
  deriving (ToJSON) via Generically Triaged

data Erased = Erased
  { project :: T.Text
  , environment :: T.Text
  }
  deriving stock (Generic)
  deriving (ToJSON) via Generically Erased

type Managing env = (HasDb env, HasClock env, HasJournal env, HasMetrics env, HasGrafana env)

type Addressed request =
  ( HasField request "project" T.Text
  , HasField request "environment" T.Text
  )

manage :: (Managing env) => env -> ManageServer
manage env =
  ManageServer
    { resolveIssue = \context request -> defMessage <$ triaging env context Resolve request
    , ignoreIssue = \context request -> defMessage <$ triaging env context Ignore request
    , reopenIssue = \context request -> defMessage <$ triaging env context Reopen request
    , erasePerson = \context request -> defMessage <$ erasing env context request
    }

jsonOnlyForManage :: Rpc.Interceptor
jsonOnlyForManage = Rpc.Interceptor \route context continue ->
  if context.requestCodec == Rpc.Json && route.service /= managed
    then Rpc.throwRpc Rpc.InvalidArgument (route.service <> " takes binary protobuf only")
    else continue context
 where
  managed = "peculiar.insights.v1.Manage"

targetOf :: (Addressed request) => request -> Target
targetOf request = Target{slug = request ^. #project, environment = request ^. #environment}

triaging :: (Managing env, Addressed request, HasField request "issue" Int64) => env -> Rpc.Context -> Disposition -> request -> IO ()
triaging env context disposition request = do
  authorised env context
  let target = targetOf request
      issue = request ^. #issue
  touched <- storing env "triage" ((getDb env).triage target disposition issue)
  unless touched (Rpc.throwRpc Rpc.NotFound ("no issue " <> T.pack (show issue) <> " in " <> target.slug <> "/" <> target.environment))
  (getJournal env).write "issue-triaged" (toJSON Triaged{project = target.slug, environment = target.environment, issue, state = stateOf disposition})

erasing :: (Managing env) => env -> Rpc.Context -> ErasePersonRequest -> IO ()
erasing env context request = do
  authorised env context
  let target = targetOf request
  erased <- storing env "erase-person" ((getDb env).erasePerson target (request ^. #userId))
  unless erased (Rpc.throwRpc Rpc.NotFound ("no such person in " <> target.slug <> "/" <> target.environment))
  (getJournal env).write "person-erased" (toJSON Erased{project = target.slug, environment = target.environment})

authorised :: (HasClock env, HasJournal env, HasGrafana env) => env -> Rpc.Context -> IO ()
authorised env context = do
  let grafana = getGrafana env
  admitted <- case Rpc.lookupHeader identityHeader context.metadata of
    Nothing -> pure (Left Anonymous)
    Just token -> do
      now <- (getClock env).now
      keys <- grafana.signingKeys
      pure (keys >>= \known -> admit grafana.organization now known token)
  case admitted of
    Right () -> pure ()
    Left refusal -> do
      (getJournal env).write "manage-refused" (toJSON (describeRefusal refusal))
      Rpc.throwRpc (codeOf refusal) (describeRefusal refusal)

codeOf :: Refusal -> Rpc.Code
codeOf = \case
  Unlinked -> Rpc.FailedPrecondition
  Anonymous -> Rpc.Unauthenticated
  KeysUnavailable _ -> Rpc.Unavailable
  Unverified _ -> Rpc.Unauthenticated
  NotAdmin _ -> Rpc.PermissionDenied
