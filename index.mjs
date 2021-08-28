import { loadStdlib } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib(process.env);

(async () => {
  const startingBalance = stdlib.parseCurrency(1000);
  const accAlice = await stdlib.newTestAccount(startingBalance);
  const accBob = await stdlib.newTestAccount(startingBalance);

  const fmt = (x) => stdlib.formatCurrency(x, 4);
  const getBalance = async (who) => fmt(await stdlib.balanceOf(who));
  const beforeAlice = await getBalance(accAlice);
  const beforeBob = await getBalance(accBob);

  const ctcAlice = accAlice.deploy(backend);
  const ctcBob = accBob.attach(backend, ctcAlice.getInfo());

  const Player = (Who) => ({
    ...stdlib.hasRandom,
    seeOutcome: (outcome) => {
      console.log(`${Who} saw outcome ${outcome ? 'Bob guessed correctly' : 'Bob guessed incorrectly'}`);
    },
    informTimeout: () => {
      console.log(`${Who} observed a timeout`);
    },
    isGamer: true,
  });

  await Promise.all([
    backend.Alice(ctcAlice, {
      ...Player('Alice'),
      wager: stdlib.parseCurrency(5),
      deadline: 10,
      getCoinflip: () => {
        const isHeads = Math.round(Math.random()) > 0;
        console.log(`Alice flipped heads ${isHeads}`);
        return isHeads;
      },
    }),
    backend.Bob(ctcBob, {
      ...Player('Bob'),
      acceptWager: async (amt) => {
        console.log(`Bob accepts the wager of ${fmt(amt)}.`);
      },
      getGuess: () => {
        const isHeads = Math.round(Math.random()) > 0;
        console.log(`Bob guessed heads ${isHeads}`);
        return isHeads;
      },
    }),
  ]);

  const afterAlice = await getBalance(accAlice);
  const afterBob = await getBalance(accBob);

  console.log(`Alice went from ${beforeAlice} to ${afterAlice}.`);
  console.log(`Bob went from ${beforeBob} to ${afterBob}.`);

})();
