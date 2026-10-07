module Test.Peculiar.Insights.Core.Cohort (tests) where

import Data.Aeson qualified as Aeson
import Data.Map.Strict qualified as Map
import Data.Text qualified as T
import Hedgehog
import Hedgehog.Gen qualified as Gen
import Hedgehog.Range qualified as Range
import Peculiar.Insights.Core.Cohort
import Peculiar.Insights.Core.Config

tests :: Group
tests =
  Group
    "Cohort"
    [ ("a quoted literal never contains a lone quote", quoting)
    , ("the view for a declared cohort", golden)
    ]

quoting :: Property
quoting = property do
  text <- forAll (Gen.text (Range.linear 0 40) Gen.unicode)
  let quoted = quoteLiteral text
  assert (T.isPrefixOf "'" quoted && T.isSuffixOf "'" quoted)
  T.count "'" (T.drop 1 (T.dropEnd 1 quoted)) === 2 * T.count "'" text

golden :: Property
golden = withTests 1 $ property do
  let project = Project{slug = "shop", environment = "prod", keyFile = "/run/key", retentionDays = Nothing, rateLimit = Nothing, denylist = [], cohorts = [], analytics = Nothing}
      cohort =
        Cohort
          { name = "payers"
          , conditions =
              [ PersonProperty PropertyCondition{key = "plan", equals = Aeson.toJSON ("pro" :: T.Text)}
              , DidEvent EventCondition{event = "purchase", filters = Map.fromList [("channel", Aeson.toJSON ("web" :: T.Text))], atLeast = 1, withinDays = 30}
              , DidNotEvent AbsenceCondition{event = "churn", filters = Map.empty, withinDays = 90}
              ]
          }
  viewName project cohort === "cohort_shop_prod_payers"
  viewSql project cohort
    === T.unlines
      [ "CREATE OR REPLACE VIEW reporting.cohort_shop_prod_payers AS"
      , "SELECT person.id AS person_id, person.user_id, project.slug AS project, project.environment"
      , "FROM person"
      , "JOIN project ON project.id = person.project_id"
      , "WHERE project.slug = 'shop'"
      , "  AND project.environment = 'prod'"
      , "  AND person.properties @> '{\"plan\":\"pro\"}'::jsonb"
      , "  AND (SELECT count(*) FROM event WHERE event.project_id = person.project_id AND event.person_id = person.id AND event.name = 'purchase' AND event.properties @> '{\"channel\":\"web\"}'::jsonb AND event.time >= now() - make_interval(days => 30)) >= 1"
      , "  AND (SELECT count(*) FROM event WHERE event.project_id = person.project_id AND event.person_id = person.id AND event.name = 'churn' AND event.time >= now() - make_interval(days => 90)) = 0"
      ]
