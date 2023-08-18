'use strict';

const express = require('express');
const os = require('os');
const fs = require('fs');

const DefMinMem = 2000000000;
const DefListnerPort = 8080;
const DefProverbs = './data/proverbs.txt';

// Constants
const PORT = process.env.PORT || DefListnerPort;
const HOST = '0.0.0.0';
const MinMemThreshold = process.env.MEMORY_THRESHOLD || DefMinMem;

// Internal functions
function getRandomInt(min, max) {
  min = Math.ceil(min);
  max = Math.floor(max);
  return Math.floor(Math.random() * (max - min) + min); // The maximum is exclusive and the minimum is inclusive
};

// App
const app = express();
app.get('/', (req, res) => {
  res.send('<h1>Welcome!</h1><hr><br>Hello World from the <b>node-api</b> simple app');
});

app.get('/health', (req, res) => {
  let goodHealth = true;
  // check the health of your machine
  // if it's ok send 200 - Health is ok
  // if not, send 503 - Issue
  console.log('Free memory: ',os.freemem());
  if (os.freemem() < MinMemThreshold) {
    goodHealth = false;
  }
  if (goodHealth) {
    res.status(200).send('<h1>Health Check</h1><hr><br>I am <b>OK!</b>');
  } else {
    res.status(503).send(`<h1>Health Check</h1><hr><br>I am <b>NOT</b> feeling well!<br>Memory: ${os.freemem()}`);
  }
});

app.get('/fortune', (req, res) => {
  let cookie = {
    fortune: '',
    luckyNumbers: []
  };
  try {
    const Proverbs = fs.readFileSync(DefProverbs).toString().split("\n");
    cookie.fortune = Proverbs[getRandomInt(0, Proverbs.length)];
    for(let i=0; i<5; i++) {
      cookie.luckyNumbers.push(getRandomInt(1, 100));
    }
    // handle success
    console.log(JSON.stringify(cookie));
    res.status(200).send(`<h1>Here is a Cookie</h1><hr><br><h3>Fortune:</h3> <li>${cookie.fortune} <br><br><h3>Lucky numbers:</h3> <li>${cookie.luckyNumbers}`);
  } catch(error) {
    // handle error
    console.error(error);
    const err = new Error('Error getting fortune cookie\n'+error);
    res.status(500).send(err.message);
  };
});

app.listen(PORT, HOST);
console.log(`Running on http://${HOST}:${PORT}`);
