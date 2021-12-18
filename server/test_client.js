const { WebSocket } = require("ws");

i = 0;

function nc() {
  const client = new WebSocket("ws://78.141.239.65:24725");

  client.i = i;

  client.on("message", (e) => {
    console.log(`${client.i} > ${e.toString()}`);
  });

  client.sendx = function (type, data) {
    client.send(JSON.stringify({ type, data }));
  };

  i++;
  return client;
}
