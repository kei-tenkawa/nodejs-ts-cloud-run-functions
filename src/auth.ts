import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth();

const targetAudience = `https://${process.env.REGION}-${process.env.PROJECT}.cloudfunctions.net/${process.env.AUTH_FUNC}`;
const url = targetAudience; // Cloud Run functions では url = targetAudience にする

export const authRequest = async () => {
  console.info(`request ${url} with target audience ${targetAudience}`);
  const client = await auth.getIdTokenClient(targetAudience);
  try {
    const res = await client.request({url});
    console.info(res.data);
  } catch (e: unknown) {
    console.error(e);
    process.exitCode = 1;
  }
}

await authRequest();