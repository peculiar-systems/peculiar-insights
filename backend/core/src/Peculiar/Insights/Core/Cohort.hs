module Peculiar.Insights.Core.Cohort
  ( viewName
  , viewSql
  , quoteLiteral
  ) where

import Data.Aeson qualified as Aeson
import Data.Aeson.Key qualified as Key
import Data.Aeson.Text qualified as AesonText
import Data.Text qualified as T
import Data.Text.Lazy qualified as TL
import Peculiar.Insights.Core.Config (AbsenceCondition (..), Cohort (..), Condition (..), EventCondition (..), Project (..), PropertyCondition (..))

viewName :: Project -> Cohort -> T.Text
viewName project cohort = "cohort_" <> project.slug <> "_" <> project.environment <> "_" <> cohort.name

viewSql :: Project -> Cohort -> T.Text
viewSql project cohort =
  T.unlines
    ( [ "CREATE OR REPLACE VIEW reporting." <> viewName project cohort <> " AS"
      , "SELECT person.id AS person_id, person.user_id, project.slug AS project, project.environment"
      , "FROM person"
      , "JOIN project ON project.id = person.project_id"
      , "WHERE project.slug = " <> quoteLiteral project.slug
      , "  AND project.environment = " <> quoteLiteral project.environment
      ]
        <> fmap (\condition -> "  AND " <> conditionSql condition) cohort.conditions
    )

conditionSql :: Condition -> T.Text
conditionSql = \case
  PersonProperty condition ->
    "person.properties @> " <> quoteLiteral (jsonText (Aeson.object [(Key.fromText condition.key, condition.equals)])) <> "::jsonb"
  DidEvent condition ->
    "(" <> eventCount condition.event condition.filters condition.withinDays <> ") >= " <> T.pack (show (max 0 condition.atLeast))
  DidNotEvent condition ->
    "(" <> eventCount condition.event condition.filters condition.withinDays <> ") = 0"
 where
  eventCount event filters days =
    "SELECT count(*) FROM event WHERE event.project_id = person.project_id AND event.person_id = person.id AND event.name = "
      <> quoteLiteral event
      <> (if null filters then "" else " AND event.properties @> " <> quoteLiteral (jsonText (Aeson.toJSON filters)) <> "::jsonb")
      <> " AND event.time >= now() - make_interval(days => "
      <> T.pack (show (max 0 days))
      <> ")"

jsonText :: Aeson.Value -> T.Text
jsonText = TL.toStrict . AesonText.encodeToLazyText

quoteLiteral :: T.Text -> T.Text
quoteLiteral text = "'" <> T.replace "'" "''" text <> "'"
