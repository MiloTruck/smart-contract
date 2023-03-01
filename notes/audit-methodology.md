# Smart Contract Audit Methodology

## Picking a target
* [Strategies for picking bounty hunting targets](https://www.joranhonig.nl/4-bug-hunting-target-strategies/)

## Before the audit

### Reading the protocol's documentation

Gain an understanding of how the system works
* What components exist in the system and how are they meant to function?
  * List down high-level functionality of what each contract aims to do
* How many different actors are there and what are their roles?
  * List down what each role should be able to do and how they interact with the contract
* Do the mechanics make sense? Or is the system design flawed regardless of the implementation?

Identify areas of interest
  * Which components of the system handle assets?
  * Which components would have the most significant impact on the system if it had a bug?
  * If you would re-build the system, where would you spend the most time?

List potential pain points and possible attack vectors.

## Research similar protocols

Learn how similar protocols are designed and implemented. 

Read previous audits reports or post-mortems and look out for common vulnerabilities for such protocols

## Beginning the audit

Examine the repository
* Look through `README.md` 
* Scan the `.sol` files for block comments that explain technical designs/gotchas
* Run the test suite
  * Examine the coverage - are there any contracts that are not tested?
  * Are there tests that look insufficient? (eg. Might not cover an edge case)

## Code Review

### Build a mental model

With the list of functionlality of all contracts and what different users should be able to do, walk through each of their the code paths and find out how the code implements these objects.  This is done to gain a high-level understanding of the contracts before focusing on details.

> **DO NOT** go through the code line-by-line, just have an idea of what each function accomplishes and the overall call path.

Note down things that seem off or confusing with an `@audit` tag and come back to it later.

### Looking for vulnerabilities

#### Resolving `@audit` tags

Go through the `@audit` tags were made earlier and resolve them, while doing the following:
* Examine the code path for edge cases
* Look out for possible bugs and mistakes in the code
* See if any common attack vectors in such protocols and are applicable 

> **DO NOT** get side-tracked other potential attacks or bugs, mark them with another `@audit` tag and come back to them later after resolving the current one.

#### Ideating Attack Vectors
After resolving all the initial `@audit` tags, it's time to come up with potential attack vectors:
* Run a static analyzer, such as [Slither](https://github.com/crytic/slither), and make all interesting results with an `@audit` tag.
* Identify all primitives an attacker has in each contract, such as:
   * What public/external functions are there in the contract?
   * How can an attacker modify the contract's state?
   * Can sending Ether or other tokens to the contract change its behavior?
 * Think of invariants that should hold for each contract, and how they could be broken.

Consider ideas that are not immediately obvious:
 * Use of non-compliant tokens (Fee-on-transfer tokens, ERC777, USDT)
 * Front-runnning
 * Gas griefing

Mark all potential attack vectors with an `@audit` tag in the code and resolve them.

#### Line-by-line Review

Do a deep review of every file - read through them line by line and focus on the implementation of each function. Go through [Smart Contract Auditing Heuristics](https://github.com/OpenCoreCH/smart-contract-auditing-heuristics) and see if any of them applies.

## Dynamic Testing

### Tests

If the test coverage is poor, write tests to fill in the missing coverage. Look for odd behavior that does not match your understanding of the contract and mark it with an `@audit` tag.

### PoCs

Write PoCs for all findings and attack vectors deemed viable, and to check if they are actually valid. If an attack is not viable as the system functions differently from your understanding, examine how your attack can be tweaked using the primitives an attacker has.

### Invariant Testing

Using methods such as formal verification and fuzzing, ensure that the invariants identified for each contract holds.

## Wrapping up the audit
Review all `@audit` tags and ensure they are all resolved.

Go through each finding and do the following:
* Ensure it is valid.
* Include the relevant details: file/line, code blocks, description, criticality, PoCs.
* Think of how each finding can be mitigated.

Finally, compile all findings into a report.

## References

* [Guardian Audit's Methodology](https://lab.guardianaudits.com/the-auditors-handbook/the-auditing-process)
* [Joran Honig's Methodology](https://twitter.com/joranhonig/status/1539578735631949825)
* [Solcurity Standard](https://github.com/transmissions11/solcurity)
* [Smart Contract Auditing Heuristics](https://github.com/OpenCoreCH/smart-contract-auditing-heuristics)