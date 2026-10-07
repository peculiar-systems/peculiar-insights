import { create } from "@bufbuild/protobuf";
import {
  ContextSchema,
  type Context,
  type Platform,
} from "../gen/peculiar/insights/v1/common_pb.js";

export type Environment = {
  readonly platform: Platform;
  readonly osName: string;
  readonly osVersion: string;
  readonly deviceModel: string;
  readonly locale: string;
  readonly timezone: string;
  readonly screenWidth: number;
  readonly screenHeight: number;
};

export type AppInfo = {
  readonly version: string;
  readonly build: string;
};

export const sdkName = "peculiar-insights-ts";

export const sdkVersion = "0.1.0";

export const contextOf = (environment: Environment, app: AppInfo): Context =>
  create(ContextSchema, {
    sdkName,
    sdkVersion,
    appVersion: app.version,
    appBuild: app.build,
    platform: environment.platform,
    osName: environment.osName,
    osVersion: environment.osVersion,
    deviceModel: environment.deviceModel,
    locale: environment.locale,
    timezone: environment.timezone,
    screenWidth: environment.screenWidth,
    screenHeight: environment.screenHeight,
  });
