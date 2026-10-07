{
  system.stateVersion = "26.11";

  services.peculiar-insights = {
    enable = true;
    listen.corsOrigins = [ "https://shop.example.org" ];
    monitoring.enable = true;
    peerLimit.forwardedHeader = "x-forwarded-for";
    projects = {
      shop.environments = {
        prod = {
          retentionDays = 400;
          denylist = [ "email" ];
          cohorts.payers = [
            {
              did_event = {
                event = "purchase";
                filters.channel = "web";
                at_least = 1;
                within_days = 30;
              };
            }
            {
              person_property = {
                key = "plan";
                equals = "pro";
              };
            }
          ];
          analytics = {
            funnels.checkout = {
              steps = [
                "checkout_opened"
                {
                  event = "payment_started";
                  filters.method = "card";
                }
                {
                  event = "order_placed";
                  label = "ordered";
                }
              ];
              windowDays = 3;
            };
            retention.weekly = {
              birth = "order_placed";
              returnEvent = {
                event = "order_placed";
                filters.channel = "web";
              };
            };
            metrics = {
              orders = {
                event = "order_placed";
                filters = {
                  gift = false;
                  channel = "web";
                };
              };
              revenue = {
                event = "order_placed";
                measure.property = "total";
              };
              slowest = {
                event = "checkout_opened";
                measure = {
                  property = "seconds";
                  aggregate = "p95";
                };
              };
            };
          };
        };
        staging = {
          keyFile = "/run/secrets/shop-staging-key";
          rateLimit = null;
        };
      };
      notes = {
        environments.prod = { };
        uploadKeyFile = "/run/secrets/notes-upload-key";
      };
    };
  };
}
