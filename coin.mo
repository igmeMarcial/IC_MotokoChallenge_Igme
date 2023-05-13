import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Moneda "Moneda";
import BootcampLocalActor "BootcampLocalActor";
import Principal "mo:base/Principal";
import Iter "mo:base/Iter";

// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"

actor class MotoCoin() {
  public type Account = Moneda.Account;

  let ledger = TrieMap.TrieMap<Moneda.Account, Nat>(Moneda.accountsEqual, Moneda.accountsHash);
  let airdropCantidad : Nat = 100;
  let bcICNetworkCanister = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
    getAllStudentsPrincipal : shared () -> async [Principal];
  };
  // stable var coinData = {
  //   name : Text = "MotoCoin";
  //   symbol : Text = "MOC";
  //   var supply : Nat = 0;
  // };

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public query func totalSupply() : async Nat {
    var total : Nat = 0;

    for ((account, balance) in ledger.entries()) {
      total += balance;
    };

    return total;
  };
  public query func getAccounts() : async [Principal] {
    let newMap = TrieMap.map<Account, Nat, Principal>(ledger, Moneda.accountsEqual, Moneda.accountsHash, func(key, value) = key.owner);
    return Iter.toArray<Principal>(newMap.vals());
  };

  public query func getAccountFromPrincipal(principal : Principal) : async Account {
    return Moneda.getAccountFromPrincipal(principal);
  };

  public func addPrincipalToLedger(principal : Principal) : async () {
    let account : Account = Moneda.getAccountFromPrincipal(principal);
    ledger.put(account, 0);
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {

    let balance : ?Nat = ledger.get(account);
    switch (balance) {
      case (null) { return 0 };
      case (?amount) { return amount };
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {

    var senderBalance : ?Nat = ledger.get(from);
    var receiverBalance : ?Nat = ledger.get(to);
    switch (senderBalance) {
      case (null) {
        return #err("El remitente no tiene saldo.");
      };
      case (?balance) {
        if (balance < amount) {
          return #err("Saldo insuficiente");
        };

        ledger.put(from, balance - amount);

        switch (receiverBalance) {
          case (null) { ledger.put(to, amount) };
          case (?rBalance) { ledger.put(to, rBalance + amount) };
        };

        return #ok();
      };
    };

    // let balFrom = await balanceOf(from);
    // if (balFrom < amount) return #err("no hay fondos suficientes");
    // let balTo = await balanceOf(to);
    // ledger.put(from, balFrom - amount);
    // ledger.put(to, balTo + amount);
    // return #ok();
    //   let balFrom : ?Nat = ledger.get(from);
    //   let balTo : ?Nat = ledger.get(to);
    //   let balFromS = await balanceOf(balFrom);

    //   if (balFrom <  amount) {
    //   return #err("insufficient funds");
    // };
    //   let newBalFrom = balFrom - amount;
    // let newBalTo = Option.get(balTo, 0) + amount;

    // ledger.put(from, newBalFrom);
    // ledger.put(to, newBalTo);

    // if (caller != from.owner) return #err("No puedes enviar activos a nombre de una cuenta que no te pertenece");
    // let balFrom = await balanceOf(from);

    // if (balFrom == null) return #err("No existe");

    // if (balFrom < amount) return #err("Saldo insuficiente");
    // let fromVR = Option.get(balFrom, 0);
    // let balTo = await balanceOf(to);
    // if (balTo == null) return #err("El destinatario no existe");
    // let balToVR = Option.get(balTo, 0);

    // ledger.put(from, balFrom - amount);
    // ledger.put(to, balTo + amount);
    // return #ok();
  };

  // Airdrop 100 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    // let bootcampLocalActor = await BootcampLocalActor.BootcampLocalActor();
    // let allStudents = await bootcampLocalActor.getAllStudentsPrincipal();

    // var currentBal : Nat = 0;
    // for (i in allStudents.vals()) {
    //   var student : Account = { owner = i; subaccount = null };
    //   currentBal := await balanceOf(student);
    //   ledger.put(student, currentBal + 100);
    //   // coinData.supply += 100;
    // };
    // return #ok();
    let principals : [Principal] = await getAllAccounts();

    for (principal in principals.vals()) {
      try {
        // Debug.print("Starting airdrop for " # debug_show(principal));
        let account : Account = Moneda.getAccountFromPrincipal(principal);
        // Debug.print("Fetched account " # debug_show(account));
        ledger.put(account, airdropCantidad);
        // Debug.print("Aidrop successful for " # debug_show(principal));
      } catch (e) {
        Debug.print("Ocurrió un error al realizar el airdrop para principal: " # Principal.toText(principal));
        return #err("Ocurrió un error al realizar el airdrop");
      };
    };

    return #ok();

  };
  private func getAllAccounts() : async [Principal] {
    // TODO: Change this to "true" for local testing.
    let isLocal : Bool = false;

    if (isLocal) {
      let bootcampTestActor = await BootcampLocalActor.BootcampLocalActor();
      let principals : [Principal] = await bootcampTestActor.getAllStudentsPrincipal();

      for (principal in principals.vals()) {
        // Debug.print("Creating ledger entry for principal: " # debug_show(principal));
        let account : Account = Moneda.getAccountFromPrincipal(principal);
        // Debug.print("Account: " # debug_show(account));
        ledger.put(account, 0);
      };

      // Debug.print("getAllAccounts() - ledger entries done");
      return principals;
    } else {
      // For the IC network.
      let principals : [Principal] = await bcICNetworkCanister.getAllStudentsPrincipal();

      for (principal in principals.vals()) {
        ledger.put(Moneda.getAccountFromPrincipal(principal), 0);
      };

      return principals;
    };
  };
};
