import join from "path.join";
import { Character } from "../types/Character.ts";
import { Spell } from "../types/Spells.ts";
import { FileType } from "../types/General.ts";

export const fileTypes: Record<FileType, {
  fileType: "json" | "hxscript",
  path: string,
}> = {
  "character": {
    fileType: "json",
    path: "../assets/data/characters",
  },
  "effect": {
    fileType: "hxscript",
    path: "../assets/data/effects",
  },
  "spell": {
    fileType: "json",
    path: "../assets/data/spells"
  },
};

type DataTypes = Character | Spell | string

export async function getAll<T extends DataTypes>(ft: FileType) {
  const { path, fileType } = fileTypes[ft];
  console.log(path)
  console.log(fileType);

  const items: Array<T> = [];
  // list all the files in the spells directory
  for await (
    const dirEntry of Deno.readDir(
      join(Deno.cwd(), path),
    )
  ) {
    console.log(dirEntry.name);
    const item = await Deno.readTextFile(
      join(Deno.cwd(), path, dirEntry.name),
    );
    items.push(fileType === "json" ? JSON.parse(item) : [dirEntry.name.split(".")[0], item]);
  }
  return items;
}

export async function pushFile<T extends DataTypes>(
  ft: FileType,
  fileName: string,
  newFile: T,
  isNew: boolean,
) {
  const { fileType, path } = fileTypes[ft];

  const workingFileName = `${fileName}.${fileType}`;

  const fileNames: Array<string> = [];

  for await (
    const dirEntry of Deno.readDir(
      join(Deno.cwd(), path),
    )
  ) {
    fileNames.push(dirEntry.name);
  }

  const isConflict = fileNames.includes(workingFileName);
  if (isConflict && isNew) {
    return "Conflict";
  }

  //write the file
  try {
    await Deno.writeTextFile(
      join(Deno.cwd(), path, workingFileName),
      typeof newFile === "string" ? newFile : JSON.stringify(newFile, null, 2),
    );
    return "Success";
  } catch (e) {
    console.log(e);
    return "Error";
  }
}
