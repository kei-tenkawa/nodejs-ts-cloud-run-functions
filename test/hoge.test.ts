import { hoge } from '@/hoge/hoge.js';

test("check", () => {
    const hogehoge = hoge();
    expect(hogehoge).toBe("hogehoge");
});
  