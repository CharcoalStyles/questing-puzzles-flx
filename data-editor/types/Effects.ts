import { z } from "zod";

export const effect = z.tuple([z.string(), z.string()]);

export type Effect = z.infer<typeof effect>;
