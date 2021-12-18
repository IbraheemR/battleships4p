const PORT = 24725;

import { WebSocketServer, WebSocket } from "ws";
import { nanoid } from "nanoid";

enum GameState {
  QUEUEING,
  PLACING,
  PLAYING,
  WIN,
}

type Client = WebSocket & { id: string };
type Coord = [number, number];
type Direction = "north" | "south" | "east" | "west";
interface BoardState {
  carrierLocation: Coord;
  carrierDirection: Direction;
  battleshipLocation: Coord;
  battleshipDirection: Direction;
  submarineLocation: Coord;
  submarineDirection: Direction;
  destroyerLocation: Coord;
  destroyerDirection: Direction;
  cruiserLocation: Coord;
  cruiserDirection: Direction;
}

function cAdd(a: Coord, b: Coord): Coord {
  return [a[0] + b[0], a[1] + b[1]];
}

function cScale(a: Coord, n: number): Coord {
  return [a[0] * n, a[1] * n];
}

function genShipLocs(loc: Coord, dir: Direction, length: number): Coord[] {
  let out = [];
  const offset = directionToOffset(dir);
  for (let i = 0; i < length; i++) {
    out.push(cAdd(loc, cScale(offset, i)));
  }

  return out;
}

function directionToOffset(d: Direction): Coord {
  if (d === "north") {
    return [1, 0];
  }
  if (d === "south") {
    return [-1, 0];
  }
  if (d === "east") {
    return [0, 1];
  }
  if (d === "west") {
    return [0, -1];
  }

  return [0, 0];
}

const BOARD_SIZE = 8;

class GameData {
  state: GameState;

  server: WebSocketServer;

  readyIds: Set<string> = new Set();

  placementData: Map<string, BoardState> = new Map();

  turnsRecieved = 0;

  coordsRemaining: Map<string, number> = new Map();

  constructor() {
    this.state = GameState.QUEUEING;
    this.server = new WebSocketServer({
      port: PORT,
    });

    this.setupWSServer();

    console.log("Server running!");
  }

  setupWSServer() {
    this.server.on("connection", (c: WebSocket) => {
      if (this.state !== GameState.QUEUEING) {
        c.send(JSON.stringify({ type: "full" }));
        c.close();
      }

      this.setupClient(c as Client);
    });
  }

  setupClient(c: Client) {
    c.id = nanoid();

    console.log(`${c.id} joined`);

    c.send(JSON.stringify({ type: "id", data: c.id }));
    c.on("message", (message) => {
      // console.log(`${c.id} > ${message.toString()}`);

      const { type, data } = JSON.parse(message.toString());

      this.handleMessage(c, type, data);
    });

    c.on("close", () => {
      console.log(`${c.id} left`);
      this.readyIds.delete(c.id);

      if (this.state !== GameState.QUEUEING) {
        this.server.close();
      }
    });
  }

  handleMessage(c: Client, type: string, data: any) {
    // TODO: handle reconnect?
    if (this.state === GameState.QUEUEING) {
      if (type === "ready") {
        this.readyIds.add(c.id);
        this.attemptStartPlacement();
      }
    } else if (this.state === GameState.PLACING) {
      if (type === "placements") {
        this.placementData.set(c.id, data); // HACK: assuming data is valid. this code is soooo jank
        this.coordsRemaining.set(c.id, 17);
        this.attemptStartPlaying();
      }
    } else if (this.state === GameState.PLAYING) {
      if (type === "shot") {
        this.turnsRecieved++;
        this.shootAt(c, data.coord, data.boardId);
        this.attemptNextRound();
      }
    } else if (this.state === GameState.WIN) {
    }
  }

  attemptStartPlacement() {
    if (this.readyIds.size < 4) return;

    this.server.clients.forEach((c) => {
      c.send(
        JSON.stringify({
          type: "start_placement",
          data: [...this.readyIds.values()].sort(),
        })
      );
    });
    this.state = GameState.PLACING;
  }

  attemptStartPlaying() {
    if (this.placementData.size < 4) return;

    this.server.clients.forEach((c) => {
      c.send(JSON.stringify({ type: "start_playing" }));
    });
    this.state = GameState.PLAYING;
  }

  shootAt(c: Client, targetCoord: any, targetBoardId: any) {
    const boardData = this.placementData.get(targetBoardId) as BoardState;
    const locations = [
      ...genShipLocs(boardData.carrierLocation, boardData.carrierDirection, 5),
      ...genShipLocs(
        boardData.battleshipLocation,
        boardData.battleshipDirection,
        4
      ),
      ...genShipLocs(
        boardData.destroyerLocation,
        boardData.destroyerDirection,
        3
      ),
      ...genShipLocs(
        boardData.submarineLocation,
        boardData.submarineDirection,
        3
      ),
      ...genShipLocs(boardData.cruiserLocation, boardData.cruiserDirection, 2),
    ].map((i) => i.toString());

    if (locations.includes(targetCoord.toString())) {
      let s = this.coordsRemaining.get(targetBoardId) as number;
      this.coordsRemaining.set(targetBoardId, s - 1);
    }

    this.server.clients.forEach((client) => {
      client.send(
        JSON.stringify({
          type: "ship_hit",
          data: {
            boardId: targetBoardId,
            coord: targetCoord,
            miss: !locations.includes(targetCoord.toString()),
          },
        })
      );
    });
  }

  attemptNextRound() {
    console.log([...this.coordsRemaining.entries()]);
    if (this.turnsRecieved < 4) return;
    if (this.attemptPlayerWin()) return;

    this.server.clients.forEach((c) => {
      c.send(JSON.stringify({ type: "new_round" }));
    });

    this.turnsRecieved = 0;
  }

  attemptPlayerWin(): boolean {
    const oneAlive =
      [...this.coordsRemaining.values()]
        .map((i) => +(i > 0))
        .reduce((a, b) => a + b) === 1;

    console.log([...this.coordsRemaining.values()].map((i) => +(i > 0)));

    if (!oneAlive) return false;

    const winnerId = [...this.coordsRemaining.entries()].filter(
      ([id, count]) => count > 0
    )[0][0];
    console.log(winnerId, "wins");

    this.server.clients.forEach((c) => {
      c.send(JSON.stringify({ type: "win", data: winnerId }));
    });

    this.server.close();

    return true;
  }
}

(async () => {
  while (true) {
    let GAME = new GameData();
    let p = new Promise((res) => {
      GAME.server.on("close", res);
    });

    await p;
  }
})();
