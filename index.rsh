'reach 0.1';

const [ isHand, HEADS, TAILS ] = makeEnum(2);

const guessWasCorrect = (coinflip, guess) => coinflip == guess;

assert(guessWasCorrect(HEADS, HEADS) == true);
assert(guessWasCorrect(TAILS, TAILS) == true);
assert(guessWasCorrect(HEADS, TAILS) == false);
assert(guessWasCorrect(TAILS, HEADS) == false);

const Player = {
  ...hasRandom,
  seeOutcome: Fun([Bool], Null),
  informTimeout: Fun([], Null),
};

export const main = Reach.App(() => {
  const Alice = Participant('Alice', {
    ...Player,
    wager: UInt, // atomic units of currency
    deadline: UInt, // time delta (blocks/rounds)
    getCoinflip: Fun([], Bool),
  });
  const Bob   = Participant('Bob', {
    ...Player,
    acceptWager: Fun([UInt], Null),
    getGuess: Fun([], Bool),
  });
  deploy();

  const informTimeout = () => {
    each([Alice, Bob], () => {
      interact.informTimeout();
    });
  };

  Alice.only(() => {
    const wager = declassify(interact.wager);
    const _coinflip = interact.getCoinflip();
    const [_commitAlice, _saltAlice] = makeCommitment(interact, _coinflip);
    const commitAlice = declassify(_commitAlice);
    const deadline = declassify(interact.deadline);
  });
  Alice.publish(wager, commitAlice, deadline)
    .pay(wager);
  commit();

  unknowable(Bob, Alice(_coinflip, _saltAlice));
  Bob.only(() => {
    interact.acceptWager(wager);
    const bobGuess = declassify(interact.getGuess());
  });
  Bob.publish(bobGuess)
    .pay(wager)
    .timeout(deadline, () => closeTo(Alice, informTimeout));
  commit();

  Alice.only(() => {
    const saltAlice = declassify(_saltAlice);
    const coinflip = declassify(_coinflip);
  });
  Alice.publish(saltAlice, coinflip)
    .timeout(deadline, () => closeTo(Bob, informTimeout));
  checkCommitment(commitAlice, saltAlice, coinflip);

  const guessedCorrectly = guessWasCorrect(coinflip, bobGuess);
  const                  [forAlice, forBob] =
    guessedCorrectly   ? [       0,      2] :
                         [       2,      0];
  transfer(forAlice * wager).to(Alice);
  transfer(forBob   * wager).to(Bob);
  commit();

  each([Alice, Bob], () => {
    interact.seeOutcome(guessedCorrectly);
  });
});
