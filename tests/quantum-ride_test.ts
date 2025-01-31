import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.14.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test ride request with incrementing IDs",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const rider = accounts.get("wallet_1")!;
    
    // Request first ride
    let block = chain.mineBlock([
      Tx.contractCall("quantum-ride", "request-ride",
        ["123 Main St", "456 Oak Ave", types.uint(1000000)],
        rider.address
      )
    ]);
    assertEquals(block.receipts[0].result, '(ok u1)');
    
    // Request second ride - should get ID 2
    block = chain.mineBlock([
      Tx.contractCall("quantum-ride", "request-ride", 
        ["789 Pine St", "321 Elm St", types.uint(1000000)],
        rider.address
      )
    ]);
    assertEquals(block.receipts[0].result, '(ok u2)');
  }
});
