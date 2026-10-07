module Peculiar.Insights.Server.Db
  ( Db (..)
  , DbError (..)
  , Stored (..)
  , ConsentRecord (..)
  , ErasureRequest (..)
  , Erased (..)
  , Retention (..)
  , Target (..)
  , Disposition (..)
  , StoredKind (..)
  , BuildCrash (..)
  , Regrouped (..)
  , KeptBuild (..)
  , stateOf
  , withDb
  , describeDbError
  ) where

import Control.Exception (IOException, bracket, try)
import Control.Monad (forM_, void)
import Data.Bifunctor (first)
import Data.Foldable (for_)
import Data.Int (Int32, Int64)
import Data.Map.Strict qualified as Map
import Data.Pool (Pool, defaultPoolConfig, destroyAllResources, newPool, setNumStripes, withResource)
import Data.Text qualified as T
import Data.Text.Encoding qualified as TE
import Data.Time (UTCTime, addUTCTime)
import Database.Beam
import Database.Beam.Backend.SQL.BeamExtensions (runInsertReturningList)
import Database.Beam.Backend.SQL.Types (SqlSerial (..))
import Database.Beam.Postgres
import Database.PostgreSQL.Simple (Only (..), execute_, query, withTransaction)
import Database.PostgreSQL.Simple.Types (Query (..))
import Peculiar.Insights.Core.Config (Project (..))
import Peculiar.Insights.Core.Item (Frame, Item, ItemId)
import Peculiar.Insights.Core.Symbols (Entry)
import Peculiar.Insights.Server.Db.Consent (consentOf, eraseOf)
import Peculiar.Insights.Server.Db.Publish (publishAll)
import Peculiar.Insights.Server.Db.Symbols
import Peculiar.Insights.Server.Db.Types
import Peculiar.Insights.Server.Migrate (migrate)
import Peculiar.Insights.Server.Projects (Registered (..))
import Peculiar.Insights.Server.Schema qualified as S

data Db = Db
  { migrateSchema :: IO (Either DbError ())
  , verify :: IO (Either DbError ())
  , registerProjects :: [Project] -> IO (Either DbError [Registered])
  , execute :: [T.Text] -> IO (Either DbError ())
  , publish :: Registered -> UTCTime -> [Item] -> Map.Map ItemId [Frame] -> IO (Either DbError [Stored])
  , recordConsent :: Registered -> UTCTime -> ConsentRecord -> IO (Either DbError Stored)
  , erase :: Registered -> UTCTime -> ErasureRequest -> IO (Either DbError Erased)
  , retain :: UTCTime -> [Retention] -> IO (Either DbError ())
  , triage :: Target -> Disposition -> Int64 -> IO (Either DbError Bool)
  , erasePerson :: Target -> T.Text -> IO (Either DbError Bool)
  , symbolEntries :: T.Text -> T.Text -> IO (Either DbError [Entry])
  , openSymbolBuild :: T.Text -> T.Text -> UTCTime -> IO (Either DbError Int32)
  , replaceSymbols :: Int32 -> T.Text -> T.Text -> [StoredKind] -> IO (Either DbError [FilePath])
  , buildCrashes :: T.Text -> T.Text -> IO (Either DbError [BuildCrash])
  , regroup :: [Regrouped] -> IO (Either DbError ())
  , symbolBuilds :: IO (Either DbError [KeptBuild])
  , dropSymbolBuilds :: [Int32] -> IO (Either DbError [FilePath])
  }

withDb :: T.Text -> (Db -> IO a) -> IO a
withDb conninfo use =
  bracket (newPool (setNumStripes (Just 1) (defaultPoolConfig (connectPostgreSQL (TE.encodeUtf8 conninfo)) close 60 8))) destroyAllResources \pool ->
    use
      Db
        { migrateSchema = guarded pool (fmap (first Migration) . migrate)
        , verify = transact pool verifyAll
        , registerProjects = \projects -> transact pool (Right <$> traverse register projects)
        , execute = \statements -> guarded pool \connection -> withTransaction connection do
            forM_ statements (execute_ connection . Query . TE.encodeUtf8)
            pure (Right ())
        , publish = \registered now items symbolicated -> transact pool (Right <$> publishAll registered now items symbolicated)
        , recordConsent = \registered now record -> transact pool (Right <$> consentOf registered.id now record)
        , erase = \registered now request -> transact pool (Right <$> eraseOf registered.id now request)
        , retain = \now retentions -> transact pool (Right <$> retainAll now retentions)
        , triage = \target disposition issue -> guarded pool \connection -> do
            touched <- query connection "SELECT admin.triage(?, ?, ?, ?)" (target.slug, target.environment, issue, stateOf disposition)
            pure (Right (touched == [Only True]))
        , erasePerson = \target user -> guarded pool \connection -> withTransaction connection do
            known <- query connection "SELECT EXISTS (SELECT 1 FROM person JOIN project ON project.id = person.project_id WHERE project.slug = ? AND project.environment = ? AND person.user_id = ?)" (target.slug, target.environment, user)
            if known == [Only True]
              then Right True <$ query @_ @(Only ()) connection "SELECT admin.delete_person(?, ?, ?)" (target.slug, target.environment, user)
              else pure (Right False)
        , symbolEntries = \project build -> transact pool (Right <$> entriesOf project build)
        , openSymbolBuild = \project build now -> transact pool (Right <$> openBuild project build now)
        , replaceSymbols = \buildId project build stored -> transact pool (Right <$> replaceKinds buildId project build stored)
        , buildCrashes = \project build -> transact pool (Right <$> crashesOf project build)
        , regroup = \regrouped -> transact pool (Right <$> regroupAll regrouped)
        , symbolBuilds = transact pool (Right <$> keptBuilds)
        , dropSymbolBuilds = \ids -> transact pool (Right <$> dropBuilds ids)
        }

guarded :: Pool Connection -> (Connection -> IO (Either DbError a)) -> IO (Either DbError a)
guarded pool action = do
  outcome <- try @SqlError (try @IOException (try @Unexpected (withResource pool action)))
  pure case outcome of
    Left failure -> Left (Unavailable (T.pack (show failure)))
    Right (Left failure) -> Left (Unavailable (T.pack (show failure)))
    Right (Right (Left (Unexpected reason))) -> Left (Unavailable reason)
    Right (Right (Right result)) -> result

transact :: Pool Connection -> Pg (Either DbError a) -> IO (Either DbError a)
transact pool action = guarded pool \connection -> withTransaction connection (runBeamPostgres connection action)

verifyAll :: Pg (Either DbError ())
verifyAll = do
  void (runSelectReturningList (select (limit_ 1 (all_ db.project))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.person))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.device))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.ingested))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.event))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.session))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.issue))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.crash))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.consent))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.erasure))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.symbolBuild))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.symbolKind))))
  void (runSelectReturningList (select (limit_ 1 (all_ db.symbolEntry))))
  pure (Right ())

register :: Project -> Pg Registered
register project = do
  existing <- runSelectReturningOne (select (filter_ (\row -> row.slug ==. val_ project.slug &&. row.environment ==. val_ project.environment) (all_ db.project)))
  row <- case existing of
    Just row -> pure row
    Nothing ->
      runInsertReturningList (insert db.project (insertExpressions [S.Project{id = default_, slug = val_ project.slug, environment = val_ project.environment}]))
        >>= single "inserting a project"
  pure Registered{id = unSerial row.id, project}

retainAll :: UTCTime -> [Retention] -> Pg ()
retainAll now retentions = do
  for_ retentions \retention -> do
    let projectId = retention.registered.id
    runDelete (delete db.event (\row -> row.projectId ==. val_ projectId &&. row.time <. val_ retention.cutoff))
    runDelete (delete db.crash (\row -> row.projectId ==. val_ projectId &&. row.time <. val_ retention.cutoff))
    runDelete (delete db.session (\row -> row.projectId ==. val_ projectId &&. row.lastSeenAt <. val_ retention.cutoff))
  runDelete (delete db.ingested (\row -> row.receivedAt <. val_ (addUTCTime (negate (120 * 86400)) now)))
