import * as ff from '@google-cloud/functions-framework'
import { hoge } from '~/src/hoge/hoge.js'

ff.http('helloGET', (req: ff.Request, res: ff.Response) => {
  const hogehoge = hoge();
  console.log(hogehoge)
  res.send(`Hello World!`);
});
