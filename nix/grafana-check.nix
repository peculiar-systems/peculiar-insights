{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.fileset) toSource unions;

  schema = toSource {
    root = ../.;
    fileset = unions [
      ../buf.yaml
      ../proto
    ];
  };

  secret = name: "$__file{${pkgs.writeText name "grafana-check-${name}"}}";
in
{
  flake.output.checks.grafana-actions = pkgs.testers.runNixOSTest {
    name = "grafana-actions";

    nodes.machine = {
      imports = [ ../nixos/module.nix ];

      virtualisation.memorySize = 2048;

      services.peculiar-insights = {
        enable = true;
        package = config.flake.packages.peculiar-insights-server;
        grafana.dashboards = ../grafana/dashboards;
        grafana.alerting = ../grafana/alerting;
        projects.shop.environments.test = { };
      };

      services.grafana = {
        enable = true;
        settings.security = {
          admin_user = "admin";
          admin_password = secret "admin";
          secret_key = secret "key";
        };
      };

      environment.systemPackages = [
        pkgs.buf
        pkgs.curl
      ];
    };

    testScript = ''
      import json
      import re
      import time

      grafana = "http://127.0.0.1:3000"
      server = "http://127.0.0.1:50051"
      admin = ("admin", "grafana-check-admin")
      editor = ("editor", "grafana-check-editor")
      viewer = ("viewer", "grafana-check-viewer")


      def curl(arguments, body=None):
          payload = "" if body is None else " --data-binary @-"
          command = "curl -s -o /tmp/answer -w '%{http_code}' " + arguments + payload
          if body is None:
              return int(machine.succeed(command))
          return int(machine.succeed(command + " <<'EOF'\n" + body + "\nEOF"))


      def grafana_json(method, path, body=None, who=admin):
          status = curl(f"-u {who[0]}:{who[1]} -X {method} -H 'Content-Type: application/json' {grafana}{path}", body)
          assert status == 200, (method, path, status, machine.succeed("cat /tmp/answer"))
          return json.loads(machine.succeed("cat /tmp/answer"))


      def sql(query):
          return machine.succeed(f"runuser -u postgres -- psql -d peculiar-insights -tAc \"{query}\"").strip()


      def interpolate(text, values):
          def replace(match):
              value = values[match.group(1)]
              return json.dumps(value) if match.group(2) == ":json" else str(value)
          return re.sub(r"\$\{([A-Za-z_.]+)(:json)?\}", replace, text)


      def perform(action, values, who):
          assert action["type"] == "fetch"
          fetch = action["fetch"]
          headers = " ".join(f"-H '{name}: {value}'" for name, value in fetch["headers"] + [["X-Grafana-Action", "1"]])
          credentials = "" if who is None else f"-u {who[0]}:{who[1]} "
          url = grafana + interpolate(fetch["url"], values)
          return curl(f"{credentials}-X {fetch['method']} {headers} '{url}'", interpolate(fetch["body"], values))


      def actions(uid, panel_id):
          dashboard = grafana_json("GET", f"/api/dashboards/uid/{uid}")["dashboard"]
          panel = next(panel for panel in dashboard["panels"] if panel["id"] == panel_id)
          return {action["title"]: action for action in panel["fieldConfig"]["defaults"]["actions"]}


      def publish(items, content_type="proto"):
          key = machine.succeed("cat /var/lib/peculiar-insights/keys/shop-test").strip()
          request = {
              "sent_at": stamp(),
              "consent": {"purposes": [
                  {"purpose": "PURPOSE_ANALYTICS", "state": "CONSENT_STATE_GRANTED", "policy_version": "v1"},
                  {"purpose": "PURPOSE_DIAGNOSTICS", "state": "CONSENT_STATE_GRANTED", "policy_version": "v1"},
              ]},
              "items": items,
          }
          if content_type == "json":
              return curl(f"-X POST -H 'Content-Type: application/json' -H 'Authorization: Bearer {key}' {server}/peculiar.insights.v1.Ingest/Publish", json.dumps(request))
          return machine.succeed(
              f"HOME=/tmp buf curl --schema ${schema} --protocol connect -H 'Authorization: Bearer {key}' "
              + f"--data '{json.dumps(request)}' {server}/peculiar.insights.v1.Ingest/Publish"
          )


      def stamp():
          return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


      def subject(user):
          return {"device_id": f"{user}-phone", "session_id": f"{user}-session", **({"user_id": user} if user else {})}


      context = {"sdk_name": "check", "sdk_version": "0", "app_version": "1.0.0", "app_build": "7", "platform": "PLATFORM_ANDROID"}


      def crash(identifier, exception, user=None):
          return {"crash_report": {
              "id": identifier,
              "time": stamp(),
              "subject": subject(user),
              "context": context,
              "exception_type": exception,
              "message": exception,
              "frames": [{"module": "ledger", "function": exception, "file": "ledger.dart", "line": 1, "column": 1, "in_app": True}],
              "fatal": True,
              "thread": "main",
          }}


      def issue_of(exception):
          return int(sql(f"SELECT issue_id FROM reporting.issue WHERE project = 'shop' AND environment = 'test' AND exception_type = '{exception}'"))


      def state_of(issue):
          return sql(f"SELECT state FROM reporting.issue WHERE issue_id = {issue}")


      machine.wait_for_unit("peculiar-insights.service")
      machine.wait_for_unit("grafana.service")
      machine.wait_for_open_port(50051)
      machine.wait_for_open_port(3000)
      machine.wait_until_succeeds(f"curl -sf -u admin:grafana-check-admin {grafana}/api/dashboards/uid/peculiar-insights-people")

      for login, password in [editor, viewer]:
          created = grafana_json("POST", "/api/admin/users", json.dumps({"name": login, "login": login, "password": password}))
          grafana_json("PATCH", f"/api/org/users/{created['id']}", json.dumps({"role": login.capitalize()}))

      publish([
          crash("00000000-0000-4000-8000-000000000001", "DetailError"),
          crash("00000000-0000-4000-8000-000000000002", "RowError"),
          {"identify": {"id": "00000000-0000-4000-8000-000000000003", "time": stamp(), "device_id": "erin-phone", "user_id": "erin"}},
          {"event": {"id": "00000000-0000-4000-8000-000000000004", "time": stamp(), "subject": subject("erin"), "context": context, "name": "opened"}},
          crash("00000000-0000-4000-8000-000000000005", "ErinError", "erin"),
      ])

      with subtest("JSON is refused outside the management service and changes nothing"):
          events = sql("SELECT count(*) FROM event")
          status = publish([{"event": {"id": "00000000-0000-4000-8000-000000000006", "time": stamp(), "subject": subject("erin"), "context": context, "name": "opened"}}], "json")
          assert status != 200, status
          assert sql("SELECT count(*) FROM event") == events

      detail = issue_of("DetailError")
      row = issue_of("RowError")
      values = {"project": "shop", "environment": "test", "issue": detail, "__data.fields.issue_id": row, "user": "erin"}
      triage = {"Resolve": "resolved", "Ignore": "ignored", "Reopen": "open"}
      sources = [("issue detail", actions("peculiar-insights-issue", 1), detail), ("crashes list row", actions("peculiar-insights-crashes", 8), row)]

      with subtest("an Editor, a Viewer and no identity triage nothing"):
          for _, declared, issue in sources:
              for title in triage:
                  for who in [editor, viewer, None]:
                      assert perform(declared[title], values, who) != 200, (title, who)
                  direct = curl(f"-X POST -H 'Content-Type: application/json' {server}/peculiar.insights.v1.Manage/{declared[title]['fetch']['url'].rsplit('/', 1)[1]}", interpolate(declared[title]["fetch"]["body"], values))
                  assert direct != 200, (title, direct)
                  assert state_of(issue) == "open", (title, state_of(issue))

      with subtest("an Admin resolves, ignores and reopens from the issue detail and from a crashes row"):
          for source, declared, issue in sources:
              assert set(declared) == set(triage), (source, set(declared))
              for title in ["Resolve", "Ignore", "Reopen"]:
                  status = perform(declared[title], values, admin)
                  assert status == 200, (source, title, status, machine.succeed("cat /tmp/answer"))
                  assert state_of(issue) == triage[title], (source, title, state_of(issue))

      erasing = actions("peculiar-insights-people", 14)["Erase"]
      person = sql("SELECT id FROM person WHERE user_id = 'erin'")

      def traces():
          return sql(
              f"SELECT (SELECT count(*) FROM person WHERE id = {person}) || ',' || (SELECT count(*) FROM event WHERE person_id = {person}) || ',' "
              + f"|| (SELECT count(*) FROM crash WHERE person_id = {person}) || ',' || (SELECT count(*) FROM device WHERE person_id = {person}) || ',' "
              + f"|| (SELECT count(*) FROM erasure WHERE person_id = {person})"
          )

      with subtest("the erase action declares a confirmation"):
          assert erasing.get("confirmation", "").strip() != ""

      with subtest("an Editor, a Viewer and no identity erase nobody"):
          before = traces()
          for who in [editor, viewer, None]:
              assert perform(erasing, values, who) != 200, who
          assert traces() == before == "1,1,1,1,0", before

      with subtest("an Admin erases the selected person, leaving only the erasure"):
          status = perform(erasing, values, admin)
          assert status == 200, (status, machine.succeed("cat /tmp/answer"))
          assert traces() == "0,0,0,0,1", traces()
    '';
  };
}
