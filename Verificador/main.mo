import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Error "mo:base/Error";
import ic "Ic";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

actor Verifier {

  // PART 1

  public type StudentProfile = {
    name : Text;
    team : Text;
    graduate : Bool;
  };

  stable var stableMap : [(Principal, StudentProfile)] = [];
  let studentProfileStore = HashMap.fromIter<Principal, StudentProfile>(stableMap.vals(), stableMap.size(), Principal.equal, Principal.hash);

  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {

    let student : StudentProfile = {
      name = profile.name;
      team = profile.team;
      graduate = profile.graduate;
    };

    studentProfileStore.put(caller, student);
    return #ok();
  };

  public shared query func seeProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    let student = studentProfileStore.get(p);

    switch (student) {
      case (null) {
        return #err("Student not found");
      };
      case (?student) {
        return #ok(student);
      };
    };
  };

  system func preupgrade() {
    stableMap := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    stableMap := [];
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    let student : ?StudentProfile = studentProfileStore.get(caller);

    switch (student) {
      case (null) {
        #err("Student not found");
      };
      case (?student) {
        let studentUpdated = {
          name = profile.name;
          team = profile.team;
          graduate = profile.graduate;
        };
        studentProfileStore.put(caller, studentUpdated);
        #ok();
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    let student : ?StudentProfile = studentProfileStore.get(caller);

    switch (student) {
      case (null) {
        #err("Student not found");
      };
      case (?student) {
        studentProfileStore.delete(caller);
        #ok();
      };
    };
  };

  // PART 2

  public type TestResult = Result.Result<(), TestError>;
  public type TestError = {
    #UnexpectedValue : Text;
    #UnexpectedError : Text;
  };

  //CanisterID e35fa-wyaaa-aaaaj-qa2dq-cai

  public shared func test(canisterId : Principal) : async TestResult {
    let calculator = actor (Principal.toText(canisterId)) : actor {
      add : (Int) -> async (Int);
      reset : () -> async (Int);
      sub : (Int) -> async (Int);
    };

    var ans : Int = 0;

    try {
      ans := await calculator.reset();
    } catch (err) {
      return #err(#UnexpectedError("Function reset is not defined"));
    };

    try {
      ans := await calculator.add(1);
    } catch (err) {
      return #err(#UnexpectedError("Function add is not defined"));
    };

    try {
      ans := await calculator.sub(1);
    } catch (err) {
      return #err(#UnexpectedError("Function sub is not defined"));
    };

    ans := await calculator.reset();
    ans := await calculator.add(1);

    if (not (ans == 1)) {
      return #err(#UnexpectedValue("Function not working"));
    };

    ans := await calculator.reset();
    ans := await calculator.sub(1);

    if (not (ans == -1)) {
      return #err(#UnexpectedValue("Function not working"));
    };

    ans := await calculator.reset();
    if (not (ans == 0)) {
      return #err(#UnexpectedValue("Function not working"));
    };

    return #ok();
  };

  // PART 3

  public func parseControllersFromCanisterStatusErrorIfCallerNotController(errorMessage : Text) : async [Principal] {
    let lines = Iter.toArray(Text.split(errorMessage, #text("\n")));
    let words = Iter.toArray(Text.split(lines[1], #text(" ")));
    var i = 2;
    let controllers = Buffer.Buffer<Principal>(0);
    while (i < words.size()) {
      controllers.add(Principal.fromText(words[i]));
      i += 1;
    };
    Buffer.toArray<Principal>(controllers);
  };

  public shared func verifyOwnership(canisterId : Principal, principalId : Principal) : async Bool {
    try {
      let ic0 = actor ("aaaaa-aa") : actor {
        canister_status : { canister_id : Principal } -> async {
          cycles : Nat;
        };
      };
      let h = await ic0.canister_status({ canister_id = canisterId });
      return false;
    } catch (e : Error) {
      let controllers : [Principal] = await parseControllersFromCanisterStatusErrorIfCallerNotController(Error.message(e));
      return not ((Array.find<Principal>(controllers, func(id : Principal) { id == principalId })) == null);
    };
  };

  // PART 4

  public shared func verifyWork(canisterId : Principal, principalId : Principal) : async Result.Result<(), Text> {

    let verify : TestResult = await test(canisterId);

    switch (verify) {
      case (#err(val)) {
        switch (val) {
          case (#UnexpectedValue(text)) { return #err(text) };
          case (#UnexpectedError(text)) { return #err(text) };
        };
      };
      case (#ok) {
        if (await verifyOwnership(canisterId, principalId)) {
          switch (studentProfileStore.get(principalId)) {
            case (null) {
              return #err("The principal does not exist");
            };
            case (?studentProfile) {
              let student : StudentProfile = {
                studentProfile with graduate = true
              };
              studentProfileStore.put(principalId, student);
            };
          };
          return #ok();
        };
        #err("Canister IDs do not match");
      };
    };
  };

};
