import * as ff from '@google-cloud/functions-framework'
import { hoge } from '@/hoge/hoge.js'

ff.http('helloGET', (req: ff.Request, res: ff.Response) => {
  let hogehoge: string = hoge();
  console.log(hogehoge)
  res.send(`Hello World!`);
});
