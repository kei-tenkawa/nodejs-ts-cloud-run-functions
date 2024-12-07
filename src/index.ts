import * as ff from '@google-cloud/functions-framework'

ff.http('helloGET', (req: ff.Request, res: ff.Response) => {
  res.send(`Hello World desu!`);
});
