import * as ff from '@google-cloud/functions-framework'
import type { HttpFunction } from "@google-cloud/functions-framework";
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

const accessSecretVersion = async (secretName: string): Promise<string | null> =>  {
  const [version] = await client.accessSecretVersion({
    name: `projects/735381230523/secrets/${secretName}/versions/latest`,
  });

  if (version && version.payload && version.payload.data) {
    return version.payload.data.toString();
  }

  return null;
}

export const helloGET: HttpFunction =  async (req: ff.Request, res: ff.Response) => {
  const mySecret = await accessSecretVersion("my-secret");
  res.send(`Hello, World! Secret is ${JSON.stringify(mySecret)}.`);
};