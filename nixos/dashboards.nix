{ lib }:
let
  inherit (lib)
    concatStringsSep
    mapAttrsToList
    replaceStrings
    imap0
    foldl'
    ;

  literal = text: "'" + replaceStrings [ "'" ] [ "''" ] text + "'";

  jsonLiteral = value: literal (builtins.toJSON value);

  datasource = {
    type = "postgres";
    uid = "peculiar-insights";
  };

  target = sql: {
    inherit datasource;
    editorMode = "code";
    format = "table";
    rawQuery = true;
    rawSql = sql;
    refId = "A";
  };

  timeSeriesTarget = sql: target sql // { format = "time_series"; };

  stat = title: sql: unit: {
    inherit datasource title;
    type = "stat";
    description = "";
    fieldConfig = {
      defaults = {
        color = {
          fixedColor = "text";
          mode = "fixed";
        };
        decimals = 1;
        thresholds = {
          mode = "absolute";
          steps = [
            {
              color = "text";
              value = null;
            }
          ];
        };
      }
      // (if unit == null then { } else { inherit unit; });
      overrides = [ ];
    };
    options = {
      colorMode = "none";
      graphMode = "none";
      justifyMode = "auto";
      orientation = "auto";
      reduceOptions = {
        calcs = [ "lastNotNull" ];
        fields = "";
        values = false;
      };
      textMode = "value";
      wideLayout = true;
    };
    targets = [ (target sql) ];
  };

  funnelCall =
    slug: environment: funnel:
    "reporting.funnel_steps(${literal slug}, ${literal environment}, ${jsonLiteral funnel.steps}::jsonb, make_interval(days => ${toString funnel.windowDays}), $__timeFrom(), $__timeTo())";

  number =
    property:
    "CASE WHEN jsonb_typeof(properties -> ${literal property}) = 'number' THEN (properties ->> ${literal property})::double precision END";

  aggregated =
    measure:
    let
      value = number measure.property;
      percentile = fraction: "percentile_cont(${fraction}) WITHIN GROUP (ORDER BY ${value})";
    in
    {
      sum = "sum(${value})";
      average = "avg(${value})";
      minimum = "min(${value})";
      maximum = "max(${value})";
      median = percentile "0.5";
      p95 = percentile "0.95";
      p99 = percentile "0.99";
    }
    .${measure.aggregate};

  measureName = measure: "${measure.aggregate} of ${measure.property}";

  funnelRows =
    slug: environment: funnel:
    "WITH f AS (SELECT step, name, people FROM ${
      funnelCall slug environment funnel
    }) SELECT step, name, people, round(100.0 * people / NULLIF(first_value(people) OVER (ORDER BY step), 0), 1) AS overall_pct, round(100.0 * people / NULLIF(lag(people) OVER (ORDER BY step), 0), 1) AS step_pct FROM f ORDER BY step";

  funnelPanels = slug: environment: name: funnel: y: [
    {
      inherit datasource;
      type = "barchart";
      title = "Funnel ${name}: people reaching each step";
      description = concatStringsSep " → " (map (step: step.label) funnel.steps);
      gridPos = {
        h = 8;
        w = 16;
        x = 0;
        inherit y;
      };
      fieldConfig = {
        defaults = {
          color = {
            fixedColor = "#2a78d6";
            mode = "fixed";
          };
          custom = {
            axisSoftMin = 0;
            fillOpacity = 90;
            lineWidth = 1;
          };
          min = 0;
        };
        overrides = [ ];
      };
      options = {
        barWidth = 0.8;
        groupWidth = 0.7;
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = false;
        };
        orientation = "auto";
        showValue = "auto";
        stacking = "none";
        tooltip = {
          mode = "single";
          sort = "none";
        };
        xField = "step";
      };
      targets = [
        (target "SELECT step || '. ' || name AS step, people FROM (${
          funnelRows slug environment funnel
        }) AS f ORDER BY step")
      ];
    }
    (
      stat "Funnel ${name}: overall conversion"
        "SELECT round(100.0 * last_value(people) OVER () / NULLIF(first_value(people) OVER (), 0), 1) AS conversion FROM (SELECT step, name, people FROM ${
          funnelCall slug environment funnel
        }) AS f ORDER BY step DESC LIMIT 1"
        "percent"
      // {
        gridPos = {
          h = 4;
          w = 8;
          x = 16;
          inherit y;
        };
      }
    )
    (
      stat "Funnel ${name}: entered" "SELECT people FROM (SELECT step, name, people FROM ${
        funnelCall slug environment funnel
      }) AS f ORDER BY step LIMIT 1" null
      // {
        gridPos = {
          h = 4;
          w = 8;
          x = 16;
          y = y + 4;
        };
      }
    )
  ];

  retentionCall =
    slug: environment: retention:
    "reporting.retention_matching(${literal slug}, ${literal environment}, ${jsonLiteral retention.birth}::jsonb, ${jsonLiteral retention.returnEvent}::jsonb, ${literal retention.period}, $__timeFrom(), $__timeTo(), ${toString retention.periods}::integer)";

  matched =
    matcher:
    if matcher.filters == { } then
      matcher.event
    else
      "${matcher.event} ${builtins.toJSON matcher.filters}";

  retentionRows =
    slug: environment: retention:
    "SELECT cohort, period, cohort_size, retained, round(100.0 * retained / NULLIF(cohort_size, 0), 1) AS retained_pct FROM ${
      retentionCall slug environment retention
    }";

  retentionPanels = slug: environment: name: retention: y: [
    {
      inherit datasource;
      type = "table";
      title = "Retention ${name}: ${retention.period}s since ${matched retention.birth}, percent returning with ${matched retention.returnEvent}";
      description = "";
      gridPos = {
        h = 10;
        w = 16;
        x = 0;
        inherit y;
      };
      fieldConfig = {
        defaults = {
          color.mode = "thresholds";
          custom = {
            align = "center";
            cellOptions = {
              mode = "gradient";
              type = "color-background";
            };
            filterable = false;
          };
          max = 100;
          min = 0;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                color = "#cde2fb";
                value = null;
              }
              {
                color = "#86b6ef";
                value = 20;
              }
              {
                color = "#3987e5";
                value = 40;
              }
              {
                color = "#1c5cab";
                value = 60;
              }
              {
                color = "#0d366b";
                value = 80;
              }
            ];
          };
          unit = "percent";
        };
        overrides = [
          {
            matcher = {
              id = "byName";
              options = "cohort\\period";
            };
            properties = [
              {
                id = "custom.cellOptions";
                value.type = "auto";
              }
              {
                id = "unit";
                value = "string";
              }
              {
                id = "custom.align";
                value = "left";
              }
            ];
          }
        ];
      };
      options = {
        cellHeight = "sm";
        footer = {
          fields = "";
          reducer = [ "sum" ];
          show = false;
        };
        showHeader = true;
      };
      transformations = [
        {
          id = "groupingToMatrix";
          options = {
            columnField = "period";
            emptyValue = "null";
            rowField = "cohort";
            valueField = "retained_pct";
          };
        }
      ];
      targets = [
        (target "SELECT to_char(cohort, 'YYYY-MM-DD') AS cohort, period, retained_pct FROM (${
          retentionRows slug environment retention
        }) AS r ORDER BY cohort, period")
      ];
    }
    {
      inherit datasource;
      type = "xychart";
      title = "Retention ${name}: average curve";
      description = "";
      gridPos = {
        h = 10;
        w = 8;
        x = 16;
        inherit y;
      };
      fieldConfig = {
        defaults = {
          color = {
            fixedColor = "#eb6834";
            mode = "fixed";
          };
          custom = {
            axisSoftMin = 0;
            lineWidth = 2;
            pointSize.fixed = 8;
            show = "points+lines";
          };
          max = 100;
          min = 0;
          unit = "percent";
        };
        overrides = [ ];
      };
      options = {
        legend = {
          displayMode = "list";
          placement = "bottom";
          showLegend = false;
        };
        mapping = "auto";
        series = [
          {
            x.matcher = {
              id = "byName";
              options = "period";
            };
            y.matcher = {
              id = "byName";
              options = "retained_pct";
            };
          }
        ];
        tooltip = {
          mode = "single";
          sort = "none";
        };
      };
      targets = [
        (target "SELECT period, round(100.0 * sum(retained) / NULLIF(sum(cohort_size), 0), 1) AS retained_pct FROM (${
          retentionRows slug environment retention
        }) AS r GROUP BY period ORDER BY period")
      ];
    }
  ];

  metricPanel = slug: environment: name: metric: x: y: {
    inherit datasource;
    type = "timeseries";
    title =
      if metric.measure == null then
        "Metric ${name}: ${metric.event} per day"
      else
        "Metric ${name}: ${measureName metric.measure} per day, over ${metric.event}";
    description = if metric.filters == { } then "" else builtins.toJSON metric.filters;
    gridPos = {
      h = 8;
      w = 12;
      inherit x y;
    };
    fieldConfig = {
      defaults = {
        color.mode = "palette-classic-by-name";
        custom = {
          axisSoftMin = 0;
          drawStyle = "line";
          fillOpacity = 10;
          gradientMode = "none";
          lineWidth = 2;
          pointSize = 5;
          showPoints = "never";
          spanNulls = false;
          stacking = {
            group = "A";
            mode = "none";
          };
        };
        min = 0;
      };
      overrides = [
        {
          matcher = {
            id = "byName";
            options = "events";
          };
          properties = [
            {
              id = "color";
              value = {
                fixedColor = "#2a78d6";
                mode = "fixed";
              };
            }
          ]
          ++ lib.optionals (metric.measure != null) [
            {
              id = "custom.axisPlacement";
              value = "right";
            }
            {
              id = "custom.fillOpacity";
              value = 0;
            }
            {
              id = "custom.lineWidth";
              value = 1;
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "value";
          };
          properties = [
            {
              id = "color";
              value = {
                fixedColor = "#1f9d6b";
                mode = "fixed";
              };
            }
            {
              id = "displayName";
              value = if metric.measure == null then "value" else measureName metric.measure;
            }
          ];
        }
        {
          matcher = {
            id = "byName";
            options = "people";
          };
          properties = [
            {
              id = "color";
              value = {
                fixedColor = "#eb6834";
                mode = "fixed";
              };
            }
          ];
        }
      ];
    };
    options = {
      legend = {
        displayMode = "list";
        placement = "bottom";
        showLegend = true;
      };
      tooltip = {
        mode = "multi";
        sort = "desc";
      };
    };
    targets = [
      (timeSeriesTarget "SELECT $__timeGroupAlias(time, '1d'), ${
        if metric.measure == null then
          "count(*) AS events, count(DISTINCT COALESCE(person_id::text, 'd:' || device_id)) AS people"
        else
          "${aggregated metric.measure} AS value, count(*) AS events"
      } FROM reporting.event WHERE project = ${literal slug} AND environment = ${literal environment} AND name = ${literal metric.event} AND properties @> ${jsonLiteral metric.filters}::jsonb AND $__timeFilter(time) GROUP BY 1 ORDER BY 1")
    ];
  };

  cohortPanel = slug: environment: cohorts: y: {
    inherit datasource;
    type = "table";
    title = "Cohort sizes";
    description = "";
    gridPos = {
      h = 8;
      w = 24;
      x = 0;
      inherit y;
    };
    fieldConfig = {
      defaults.custom = {
        align = "auto";
        cellOptions.type = "auto";
        filterable = true;
      };
      overrides = [ ];
    };
    options = {
      cellHeight = "sm";
      footer = {
        fields = "";
        reducer = [ "sum" ];
        show = false;
      };
      showHeader = true;
    };
    targets = [
      (target (
        concatStringsSep " UNION ALL " (
          mapAttrsToList (
            name: _:
            "SELECT ${literal name} AS cohort, count(*) AS people FROM reporting.cohort_${slug}_${environment}_${name}"
          ) cohorts
        )
      ))
    ];
  };

  numbered = panels: imap0 (index: panel: panel // { id = index + 1; }) panels;

  layout =
    slug: environment: analytics: cohorts:
    let
      funnels =
        foldl'
          (acc: name: {
            y = acc.y + 8;
            panels = acc.panels ++ funnelPanels slug environment name analytics.funnels.${name} acc.y;
          })
          {
            y = 0;
            panels = [ ];
          }
          (builtins.attrNames analytics.funnels);
      retention = foldl' (acc: name: {
        y = acc.y + 10;
        panels = acc.panels ++ retentionPanels slug environment name analytics.retention.${name} acc.y;
      }) funnels (builtins.attrNames analytics.retention);
      metricNames = builtins.attrNames analytics.metrics;
      metrics = foldl' (
        acc: name:
        let
          index = acc.count;
          x = if lib.mod index 2 == 0 then 0 else 12;
          y = acc.y + 8 * (index / 2);
        in
        {
          inherit (acc) y;
          count = index + 1;
          panels = acc.panels ++ [ (metricPanel slug environment name analytics.metrics.${name} x y) ];
        }
      ) (retention // { count = 0; }) metricNames;
      afterMetrics = metrics.y + 8 * ((metrics.count + 1) / 2);
      withCohorts =
        if cohorts == { } then
          metrics.panels
        else
          metrics.panels ++ [ (cohortPanel slug environment cohorts afterMetrics) ];
    in
    numbered withCohorts;
in
{
  forEnvironment =
    {
      slug,
      environment,
      analytics,
      cohorts,
    }:
    {
      annotations.list = [ ];
      description = "Funnels, retention, metrics and cohorts declared for ${slug} / ${environment} in the host configuration";
      editable = false;
      graphTooltip = 1;
      links = [
        {
          asDropdown = true;
          icon = "external link";
          includeVars = false;
          keepTime = true;
          tags = [ "peculiar-insights" ];
          targetBlank = false;
          title = "Peculiar Insights";
          type = "dashboards";
        }
      ];
      panels = layout slug environment analytics cohorts;
      refresh = "";
      schemaVersion = 39;
      tags = [
        "peculiar-insights"
        "insights-${slug}"
      ];
      templating.list = [ ];
      time = {
        from = "now-30d";
        to = "now";
      };
      timepicker = { };
      timezone = "browser";
      title = "${slug} / ${environment}";
      uid = "insights-${slug}-${environment}";
      version = 1;
    };
}
