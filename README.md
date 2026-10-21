# Tensormesh-assignment
All designs are written in Verilog and tested with Quartus prime and simulated in Questasim
# TensorMesh Assignment (Parts 1, 2 and 3)

All the designs are in Verilog. I simulated them in Quartus using the simulator that comes with it. Every testbench is self checking and prints PASS or FAIL at the end.


## Folder layout

```
part1/
    part_1.v
    tb_part1.v
    state_diagram
part2/
    part_2_fixed.v      (version 1, fixed priority)
    part_2_fair.v       (version 2, round robin)
    tb_part2.v
part3/
    part3.v
    tb_part3.v
    fsm_diagram
    block_diagram
```

(testbench and diagram file names: write your own names here)

Also a attached pdf file is there which contains requied state diagrams and block diagrams and necessary explanations

For part 2 compile both designs with the testbench, and for part 3 use `part3.v`. In Quartus I did the same thing from the GUI (Tools, Run Simulation Tool). Change the testbench names above to the ones in the repo.

Reset is synchronous and active high (`rst`) in all the parts.

---

# Part 1: Prime number counter FSM

File: `part_1.v`, module `part_1`.

It is a 3 state FSM with a 4 bit counter. When it is running the counter goes 2, 3, 5, 7, 11, 13 and then back to 2.

## State diagram

The diagram is in the part1 folder. Here is the same thing in a table.

| From | Condition | To | What count does |
|---|---|---|---|
| IDLE | start = 0 | IDLE | holds |
| IDLE | start = 1 | ACTIVE | loads 2 |
| ACTIVE | stop = 0 | ACTIVE | goes to the next prime |
| ACTIVE | stop = 1 | DONE | holds |
| DONE | always | IDLE | holds |
| any state | rst = 1 | IDLE | becomes 0 |

State encoding in the code: IDLE = 00, ACTIVE = 01, DONE = 10.

If start and stop are both high in ACTIVE then stop wins. The next state logic in ACTIVE only looks at stop, and start is only looked at in IDLE.

## How I wrote it

The code is split in three blocks like the question wanted.

1. State register. Clocked block. On reset state goes to IDLE, otherwise it takes next_state.
2. Next state logic. Combinational `case` on state, written with blocking assignments.
3. Counter block. Clocked block. Reset is checked first. In IDLE with start high it loads 2. In ACTIVE with stop low it goes to the next prime using a `case`. In every other situation there is no assignment so count just keeps its old value.

## What happens when stop goes high at count = 7

The question only says count holds in IDLE and DONE, it does not say what happens on the exact clock edge where stop is seen. I made count hold on that edge. So it stays 7 and does not jump to 11. I did this because the counter only moves when the state is ACTIVE and stop is low.

Values after each clock edge:

| Step | state | count | start | stop | note |
|---|---|---|---|---|---|
| after reset | IDLE | 0 | 0 | 0 | |
| start is high | ACTIVE | 2 | 1 | 0 | loads 2 |
| next clock | ACTIVE | 3 | 0 | 0 | |
| next clock | ACTIVE | 5 | 0 | 0 | |
| next clock | ACTIVE | 7 | 0 | 1 | stop goes high here |
| next clock | DONE | 7 | 0 | 0 | held, did not become 11 |
| next clock | IDLE | 7 | 0 | 0 | DONE lasted one cycle |
| next clock | IDLE | 7 | 0 | 0 | still holding |
| start is high | ACTIVE | 2 | 1 | 0 | restart loads 2, not 7 |

## Reset and hold

Reset and hold are different things. Hold just means I do not assign anything to count in that state, so the flip flop keeps the old value. Reset is checked first in the block so it beats everything. So after a stop, count stays at its value until start loads 2 or rst makes it 0.

## Assumptions

1. After reset count is 0. That is not a prime but it only matters in ACTIVE.
2. On the stop edge count holds (explained above).
3. start is ignored in ACTIVE and DONE. stop is ignored in IDLE and DONE.
4. If count ever has a weird value in ACTIVE (it should not), the code sends it to 2.

## Bonus

I did not do the bonus. The next prime is done with a `case` lookup.

## Testbench

The testbench checks these things:

1. reset gives IDLE and count 0
2. start goes to ACTIVE and count is 2
3. full sequence with the wrap from 13 to 2
4. stop goes to DONE
5. DONE lasts one clock and then goes to IDLE
6. count holds in IDLE
7. restart loads 2 again
8. stop at count 7 keeps 7
9. start and stop together in ACTIVE, stop wins
10. count is always one of 2, 3, 5, 7, 11, 13 while in ACTIVE

Result: (paste your PASS line here)

---

# Part 2: Shared resource arbiter

I made two separate files, one for each version.

| File | Version |
|---|---|
| `part_2_fixed.v` | Version 1, fixed priority (A always wins) |
| `part_2_fair.v` | Version 2, fair arbiter (round robin) |

Both have the same ports: `clk`, `rst`, `req_A`, `req_B`, `data_A`, `data_B` in and `grant_A`, `grant_B`, `out_data`, `out_valid` out.

## How each version works

Behaviour table:

| req_A | req_B | Fixed | Fair |
|---|---|---|---|
| 0 | 0 | no grant, out_valid = 0, out_data = 0 | same |
| 1 | 0 | grant A | grant A |
| 0 | 1 | grant B | grant B |
| 1 | 1 | grant A | grant whoever was not granted last |

Grants are combinational. That means the grant shows up in the same cycle as the request, there is no clock delay. out_data is taken from the module that has the grant and both grants are never high together.

Version 1 has no memory at all. It is just an if / else if with A first. Because of that it does not use `clk` or `rst`. I kept them in the port list so both versions have the same interface.

Version 2 has one extra flip flop called `last_B`. It is 1 if B was granted last and 0 if A was granted last. When both request, if `last_B` is 1 then A wins, otherwise B wins. The flop is updated only in a cycle where a grant actually happens (out_valid is high). So when nobody requests, it keeps its value. On reset `last_B` is 1, so the very first tie goes to A.

## Assumptions

1. Reset value of `last_B` is 1, so A wins the first tie.
2. A module that loses keeps its request high until it is served.
3. When there is no grant, out_data is 0 and out_valid is 0.
4. `last_B` is updated on solo grants too (not only on ties), so it always shows who was granted last.

## Answers

### 1. What happens when both requests come at the same time?

Fixed version: A wins. B has to wait until A drops its request. Fair version: it depends on who was granted last. After reset A wins the first tie, and after that they take turns.

Both requests held high for 4 cycles:

| Cycle | req_A | req_B | Fixed grant | Fair grant |
|---|---|---|---|---|
| 0 | 1 | 1 | A | A |
| 1 | 1 | 1 | A | B |
| 2 | 1 | 1 | A | A |
| 3 | 1 | 1 | A | B |

If A drops its request after getting served in cycle 0, then B is served in cycle 1 in both versions. The difference is only when A keeps requesting.

If A was the last one granted before the tie, the fair version gives the tie to B straight away.

### 2. What is the problem with always giving A priority?

B can starve. As long as A keeps its request high, B never gets a grant, even if B has been waiting for ages. I tested this by holding both requests high for 20 cycles and counting the grants.

| Version | grants to A | grants to B |
|---|---|---|
| Fixed | 20 | 0 |
| Fair | 10 | 10 |

(these are the numbers from the code, please check them against what your testbench prints)

### 3. How does version 2 make it fair and what is the longest B can wait?

It remembers who got the last grant. The one who just won cannot win the next tie, so if B loses once, `last_B` becomes 0 and B wins the next time both request. So B waits at most 1 cycle (the one cycle where A is served) as long as it keeps its request high. This is also why the grants alternate when both requests are held for 10 or more cycles.

## Testbench

It covers:

1. A alone
2. B alone
3. both together
4. neither
5. both held for 10 or more cycles (fair version must alternate)
6. a checker that fails if both grants are ever high at the same time
7. a checker that fails if out_data does not match the granted module
8. the 20 cycle test that counts grants for B in both versions

Result: (paste your PASS line and the grant counts here)

---

# Part 3: Smart crossroads controller

File: `part3.v`, module `part3`. Everything is in one module, but I split it into three parts inside the file: the selector, the FSM with timer and wait counters, and the output decoding.

## Ports

Inputs: `clk`, `rst`, `dens_N`, `dens_E`, `dens_S`, `dens_W` (2 bits each, 0 empty, 1 light, 2 medium, 3 heavy).
Outputs: `green[3:0]`, `yellow[3:0]`, in the order {W, E, S, N}.

Since the order is {W, E, S, N}, the bit positions are:

| Bit | Direction |
|---|---|
| 0 | N |
| 1 | S |
| 2 | E |
| 3 | W |

A direction is red when both its green and yellow bit are 0.

Inside the module I use my own direction numbers in the order the tie rule goes: N = 0, E = 1, S = 2, W = 3. These are only converted to the output bit positions at the output decoding part, so the tie rule can just add 1 and wrap around.

## How it works

There are three phases that keep repeating.

| Phase | Length | Outputs |
|---|---|---|
| SELECT | 1 tick | everything red |
| GREEN | 4 + 2 x density ticks (4, 6, 8 or 10) | chosen direction green |
| YELLOW | 2 ticks | chosen direction yellow |

One full SELECT, GREEN, YELLOW is what I call a phase. So a phase is 7 to 13 ticks long.

In SELECT the controller picks one direction, saves it in `chosen`, works out the green time from that direction's density and loads the wait counters. The densities are looked at only in this one tick. While GREEN and YELLOW are running the live densities are ignored.

### How the direction is picked (selector)

It is a combinational block with this order of priority:

1. Starvation first. If any wait counter is 3 or more, only those directions can be picked. If more than one is 3 or more, the one with the biggest wait count is kept.
2. If nothing is forced, the directions with the highest density are kept.
3. If more than one direction is left, I go around in the order N, E, S, W starting from the one after the last served, and take the first one that is still in the list. When all the densities are 0 every direction is tied, so it just keeps rotating in the same order.

### Wait counters

Each direction has a 3 bit wait counter. When a direction is picked its counter goes to 0, and the other three go up by 1. They stop at 7 so they cannot overflow. The update happens in the SELECT tick, at the same time the direction is picked. The selector uses the counter values from before this update.

### Timer

One 4 bit timer. It is set to 0 in SELECT. In GREEN it counts up and moves to YELLOW once it has counted `green_length` ticks. In YELLOW it counts 2 ticks and then goes back to SELECT.

## Assumptions

1. After reset the controller starts in SELECT, and all wait counters are 0.
2. `last_served` is W after reset. So if everything is tied at the start, N goes first.
3. The wait counters are updated in the SELECT tick, when the direction is chosen.
4. The counters are 3 bits and stop at 7. This is more than needed (see the bound below) but it keeps the "who waited longest" comparison working when more than one direction is forced.
5. If more than one direction is forced and they have the same wait count, the tie goes by the N, E, S, W order after the last served.
6. A forced direction gets a green time from its own density, same as every other direction.
7. I kept the numbers from the question: green is 4 + 2 x density, yellow is 2 ticks and SELECT is 1 tick.
8. Turning traffic and pedestrians are not handled.

## Diagrams

- `fsm_diagram`: SELECT, GREEN and YELLOW with what makes it move to the next one (selection done, green timer finished, yellow timer finished).
- `block_diagram`: selector, wait counters, timer and the main FSM, with the wires between them.

## Testbench checkers

The testbench fails the test if it sees any of these:

1. more than one green bit high
2. a green on one direction and a yellow on a different direction at the same time
3. two different greens without a SELECT (all red) tick in between
4. any direction waiting more than 5 phases

Here "waiting" means the number of phases served to other directions since that direction was last served.

## Scenarios

1. Uniform: all four densities at 2. Green time should be about the same for all.
2. One heavy: N is 3 and the others are 1. N should get the most green, and the others should still get served.
3. Rapidly changing: densities change every 1 to 3 ticks for at least 300 ticks from a random generator with a fixed seed, plus one scripted case where the busy direction changes from N to E in the middle.

Seed used: (write your seed here)

## Results

| Scenario | Direction | Green ticks | Phases | Longest wait (phases) |
|---|---|---|---|---|
| Uniform | N | | | |
| Uniform | E | | | |
| Uniform | S | | | |
| Uniform | W | | | |
| One heavy | N | | | |
| One heavy | E | | | |
| One heavy | S | | | |
| One heavy | W | | | |
| Random + scripted | N | | | |
| Random + scripted | E | | | |
| Random + scripted | S | | | |
| Random + scripted | W | | | |

(fill these from your simulation log)

## Explanation

Two greens can never happen together because only one direction is stored in `chosen` and the output decoding sets just that one bit, and every green and yellow is followed by a SELECT tick where everything is red. No direction starves because each one has a wait counter that goes up every time someone else is served, and once it reaches 3 that direction is picked next whatever the densities are. If a few of them reach 3 together, they are served one after the other with the longest waiter first. My bound is 5 phases. A direction needs at most 3 phases of others before its counter hits 3, and after that at most 2 other forced directions can be ahead of it, so 3 + 2 = 5. For example if N is served 3 times in a row then E, S and W are all at 3, and E, then S, then W are served, so W waits for N, N, N, E, S which is 5 phases.

---

## Not done


