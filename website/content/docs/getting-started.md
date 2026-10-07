---
title: Getting started
section: Start
order: 2
---

# Getting started

From nothing to the first event in Grafana. Five steps, each one short.

## 1. Deploy the module

On the NixOS host, import the flake's module and enable it, with Grafana enabled beside it. With the defaults it runs PostgreSQL, creates the database and the `grafana` reader role, and provisions the datasource, dashboards and alert rules into the host's Grafana.

```nix
{
  inputs.peculiar-insights.url = "github:peculiar-systems/peculiar-insights";

  outputs = { nixpkgs, peculiar-insights, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      modules = [
        peculiar-insights.nixosModules.default
        { services.peculiar-insights.enable = true; }
      ];
    };
  };
}
```

TLS terminates at your reverse proxy, or the module serves it directly with `listen.tls`. See [Deploying with NixOS](/docs/deploying) for every option.

## 2. Declare the project next to the product

The `projects` option merges across modules, so the product's own module is the place:

```nix
{ config, ... }:
{
  services.shop.enable = true;
  services.peculiar-insights.projects.shop.environments.prod = {
    retentionDays = 400;
  };
}
```

Nothing else is needed. The service generates the ingest key at first start and exports its path as `config.services.peculiar-insights.keyFiles."shop/prod"`.

## 3. Give the product the key

A product on the same host loads the key as a credential:

```nix
systemd.services.shop = {
  after = [ "peculiar-insights.service" ];
  serviceConfig.LoadCredential = [
    "insights-key:${config.services.peculiar-insights.keyFiles."shop/prod"}"
  ];
};
```

A phone app or a browser bundle needs the key at build time; copy it from the host through the secret channel you already use. For a web product, add its origin to `listen.corsOrigins`.

## 4. Integrate one SDK

Start the SDK once with the URL, the key and a consent policy, then record through trackers. Flutter, as one example:

```dart
final insights = await FlutterInsights.start(
  url: Uri.parse("https://insights.example.org"),
  key: key,
  consent: const ConsentPolicy.ask(),
);

final checkout = insights.tracker.with_({"screen": "checkout"});
await checkout.track("order_placed", {"total": 42.5, "items": 3});
```

Wire the product's consent prompt to `insights.consent.grant`; before a decision the SDK sends nothing. The [Flutter](/docs/sdks/flutter), [TypeScript](/docs/sdks/typescript) and [Haskell](/docs/sdks/haskell) pages cover each SDK, and [For agents](/docs/agents) points at the document to hand an agent that does the integration for you.

## 5. Look at Grafana

Open Grafana on the host, pick `shop` and `prod` in the dashboard variables, and the event appears in the overview and in event segmentation within seconds. Declare funnels, retention and metrics next to the project when you want them, and the environment gets its own dashboard in its own folder; see [Grafana](/docs/grafana).
