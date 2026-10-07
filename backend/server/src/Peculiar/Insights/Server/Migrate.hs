{-# LANGUAGE TemplateHaskell #-}

module Peculiar.Insights.Server.Migrate
  ( migrate
  , MigrateError (..)
  , describeMigrateError
  ) where

import Control.Exception (try)
import Data.Bifunctor (first)
import Data.ByteString qualified as BS
import Data.FileEmbed (embedDir)
import Data.Foldable (foldlM)
import Data.Functor ((<&>))
import Data.List (sortOn)
import Data.Text qualified as T
import Database.PostgreSQL.Simple (Connection, Only (..), SqlError, execute, execute_, query_, withTransaction)
import Database.PostgreSQL.Simple.Types (Query (..))

migrations :: [(FilePath, BS.ByteString)]
migrations = sortOn fst $(embedDir "migrations")

data MigrateError = MigrateFailed T.Text T.Text
  deriving stock (Eq, Show)

describeMigrateError :: MigrateError -> T.Text
describeMigrateError (MigrateFailed name reason) = "migration " <> name <> " failed: " <> reason

migrate :: Connection -> IO (Either MigrateError ())
migrate connection =
  prepare >>= \case
    Left failure -> pure (Left failure)
    Right applied -> foldlM step (Right ()) [m | m@(name, _) <- migrations, name `notElem` applied]
 where
  prepare =
    try @SqlError do
      _ <- execute_ connection "CREATE TABLE IF NOT EXISTS schema_migration (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())"
      fmap fromOnly <$> query_ connection "SELECT name FROM schema_migration"
      <&> first (MigrateFailed "schema_migration" . T.pack . show)
  step (Left failure) _ = pure (Left failure)
  step (Right ()) (name, sql) =
    try @SqlError
      ( withTransaction connection do
          _ <- execute_ connection (Query sql)
          _ <- execute connection "INSERT INTO schema_migration (name) VALUES (?)" (Only name)
          pure ()
      )
      <&> first (MigrateFailed (T.pack name) . T.pack . show)
