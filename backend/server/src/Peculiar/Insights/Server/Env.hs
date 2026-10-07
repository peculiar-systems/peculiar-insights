module Peculiar.Insights.Server.Env
  ( Env (..)
  , HasDb (..)
  , HasClock (..)
  , HasJournal (..)
  , HasProjects (..)
  , HasLimits (..)
  , HasLimiter (..)
  , HasMetrics (..)
  , HasGrafana (..)
  , HasSymbolicator (..)
  , HasUploads (..)
  ) where

import Peculiar.Insights.Core.Config (PeerLimit)
import Peculiar.Insights.Core.Time (Window)
import Peculiar.Insights.Core.Validate (Limits)
import Peculiar.Insights.Server.Clock (Clock)
import Peculiar.Insights.Server.Db (Db)
import Peculiar.Insights.Server.Grafana (Grafana, HasGrafana (..))
import Peculiar.Insights.Server.Journal (Journal)
import Peculiar.Insights.Server.Limiter (Limiter)
import Peculiar.Insights.Server.Metrics (HasMetrics (..), Metrics)
import Peculiar.Insights.Server.Projects (Projects)
import Peculiar.Insights.Server.Symbolicator (Symbolicator)
import Peculiar.Insights.Server.Uploads (Uploads)

data Env = Env
  { db :: Db
  , clock :: Clock
  , journal :: Journal
  , projects :: Projects
  , limits :: Limits
  , window :: Window
  , limiter :: Limiter
  , peerLimit :: Maybe PeerLimit
  , metrics :: Metrics
  , grafana :: Grafana
  , symbolicator :: Symbolicator
  , uploads :: Uploads
  }

class HasDb env where
  getDb :: env -> Db

class HasClock env where
  getClock :: env -> Clock

class HasJournal env where
  getJournal :: env -> Journal

class HasProjects env where
  getProjects :: env -> Projects

class HasLimits env where
  getLimits :: env -> Limits
  getWindow :: env -> Window

class HasSymbolicator env where
  getSymbolicator :: env -> Symbolicator

class HasUploads env where
  getUploads :: env -> Uploads

class HasLimiter env where
  getLimiter :: env -> Limiter
  getPeerLimit :: env -> Maybe PeerLimit

instance HasDb Env where
  getDb env = env.db

instance HasClock Env where
  getClock env = env.clock

instance HasJournal Env where
  getJournal env = env.journal

instance HasProjects Env where
  getProjects env = env.projects

instance HasLimits Env where
  getLimits env = env.limits
  getWindow env = env.window

instance HasLimiter Env where
  getLimiter env = env.limiter
  getPeerLimit env = env.peerLimit

instance HasMetrics Env where
  getMetrics env = env.metrics

instance HasGrafana Env where
  getGrafana env = env.grafana

instance HasSymbolicator Env where
  getSymbolicator env = env.symbolicator

instance HasUploads Env where
  getUploads env = env.uploads
