import { release, type } from "node:os";
import { Platform } from "../gen/peculiar/insights/v1/common_pb.js";
import type { Environment } from "../core/context.ts";

export const nodeEnvironment = (): Environment => ({
  platform: Platform.SERVER,
  osName: type(),
  osVersion: release(),
  deviceModel: "",
  locale: Intl.DateTimeFormat().resolvedOptions().locale,
  timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  screenWidth: 0,
  screenHeight: 0,
});
