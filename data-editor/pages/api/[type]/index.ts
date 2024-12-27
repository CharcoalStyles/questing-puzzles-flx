// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from "next";
import { Character, character } from "../../../types/Character.ts";
import { getAll, pushFile } from "../../../lib/fileAccess.ts";
import { fileType } from "../../../types/General.ts";
import { spell, Spell } from "../../../types/Spells.ts";
import { Effect, effect } from "../../../types/Effects.ts";

type Data = Array<Character> | Array<string> | Array<Spell>;

export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<Data>,
) {
  console.log("Data root API");
  const { type } = req.query;
  if (!req.method) {
    res.setHeader("Allow", ["GET", "POST", "PUT"]);
    res.status(405).end(`Method ${req.method} Not Allowed`);
    return;
  }

  if (!type) {
    res.status(400).end();
    return;
  }

  const { success, data: fType } = fileType.safeParse(type);

  if (success === false) {
    res.status(400).end();
    return;
  }

  console.log({fType});

  if (req.method === "GET") {
    switch (fType) {
      case "character":
        res.status(200).json(await getAll<Character>("character"));
        break;
      case "effect": {
        const x = await getAll<string>("effect");
        console.log('mmm', x);
        res.status(200).json(await getAll<string>("effect"));
        break;
      }
      case "spell":
        res.status(200).json(await getAll<Spell>("spell"));
        break;
    }
    res.end();
    return;
  }

  if (["POST", "PUT"].includes(req.method)) {
    console.log("POST/PUT");
    try {
      console.log(req.body);

      let fileName: string;
      let resp: string;

      switch (fType) {
        case "character": {
          const body = character.parse(req.body);
          fileName = body.name.split(" ").join("_");

          resp = await pushFile<Character>(
            "character",
            fileName,
            body,
            req.method === "POST",
          );
          break;
        }
        case "effect": {
          const body = effect.parse(req.body);
          fileName = body[0].split(" ").join("_");

          resp = await pushFile<string>(
            "effect",
            fileName,
            body[1],
            req.method === "POST",
          );
          break;
        }
        case "spell": {
          const body = spell.parse(req.body);
          fileName = body.name.split(" ").join("_");

          resp = await pushFile<Spell>(
            "spell",
            fileName,
            body,
            req.method === "POST",
          );
          break;
        }
      }

      console.log({ resp });
      if (resp === "Success") {
        res.status(201).end();
        return;
      }
      if (resp === "Conflict") {
        res.status(409).end();
        return;
      }
      res.status(500).end();
      return;
    } catch (e) {
      console.log(e);
      return res.status(400).end();
    }
  }

  res.setHeader("Allow", ["GET", "POST", "PUT"]);
  return res.status(405).end(`Method ${req.method} Not Allowed`);
}
