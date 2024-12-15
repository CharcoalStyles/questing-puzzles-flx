// Next.js API route support: https://nextjs.org/docs/api-routes/introduction
import type { NextApiRequest, NextApiResponse } from "next";
import join from "path.join";
import { Character, character } from "../../../types/Character.ts";

type Data = Array<Character>;
export default async function handler(
  req: NextApiRequest,
  res: NextApiResponse<Data>,
) {
  console.log("Character root API"); 
  if (!req.method) {
    res.setHeader("Allow", ["GET", "POST", "PUT"]);
    res.status(405).end(`Method ${req.method} Not Allowed`);
    return;
  }

  if (req.method === "GET") {
    res.status(200).json(await getAll());
    return;
  }

  if (["POST", "PUT"].includes(req.method)) {
    console.log("POST/PUT");
    try {
      console.log(req.body);
      const newCharacter = character.parse(req.body);

      const resp = await push(newCharacter, req.method === "POST");
      console.log({resp});
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

async function getAll() {
  const characters: Array<Character> = [];
  // list all the files in the spells directory
  for await (
    const dirEntry of Deno.readDir(
      join(Deno.cwd(), "../assets/data/characters"),
    )
  ) {
    console.log(dirEntry.name);
    const char = await Deno.readTextFile(
      join(Deno.cwd(), "../assets/data/characters", dirEntry.name),
    );
    characters.push(JSON.parse(char));
  }
  return characters;
}

async function push(newCharacter: Character, isNew: boolean) {
  const fileName = `${newCharacter.name.split(" ").join("_")}.json`;
  const fileNames: Array<string> = [];

  for await (
    const dirEntry of Deno.readDir(
      join(Deno.cwd(), "../assets/data/characters"),
    )
  ) {
    fileNames.push(dirEntry.name);
  }

  const isConflict = fileNames.includes(fileName);
  if (isConflict && isNew) {
    return "Conflict";
  }

  //write the file
  try {
    await Deno.writeTextFile(
      join(Deno.cwd(), "../assets/data/characters", fileName),
      JSON.stringify(newCharacter, null, 2),
    );
    return "Success";
  } catch (e) {
    console.log(e);
    return "Error";
  }
}
