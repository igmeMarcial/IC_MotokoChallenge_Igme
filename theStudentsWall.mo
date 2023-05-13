import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Order "mo:base/Order";
import Int "mo:base/Int";
import Text "mo:base/Text";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;

  var messageId : Nat = 0;
  private func _hashNat(n : Nat) : Hash.Hash = return Text.hash(Nat.toText(n));

  let wall = HashMap.HashMap<Nat, Message>(0, Nat.equal, _hashNat);
  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {

    let newMessageId : Nat = messageId;
    messageId := messageId + 1;
    let newMessage : Message = {
      content = c;
      vote = 0;
      creator = caller;
    };
    wall.put(newMessageId, newMessage);

    return newMessageId;
  };

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    let messageOpt = wall.get(messageId);
    switch (messageOpt) {
      case (null) {
        return #err("Mensaje no encontrado1");
      };
      case (?ok) {
        return #ok(ok);
      };
    };
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {

    let messageOpt = wall.get(messageId);
    switch (messageOpt) {
      case (null) {
        return #err("Mensaje no encontrado2");
      };
      case (?ok) {
        let updatedMessage : Message = {
          content = c;
          vote = ok.vote;
          creator = caller;
        };
        wall.put(messageId, updatedMessage);
        return #ok(());

      };
    };

  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    let messageOpt = wall.get(messageId);
    switch (messageOpt) {
      case (null) {
        return #err("Mensaje no encontrado3");
      };
      case (?ok) {
        let deleteMessage = wall.remove(messageId);
        return #ok(());
      };
    };

  };

  // Voting
  public shared func upVote(messageId : Nat) : async Result.Result<(), Text> {
    let messageResult = wall.get(messageId);
    switch (messageResult) {
      case (null) {
        return #err("Message not found1");
      };
      case (?ok) {
        let voteUp : Message = {
          content = ok.content;
          vote = ok.vote + 1;
          creator = ok.creator;
        };

        wall.put(messageId, voteUp);
        return #ok(());
      };
    };
  };

  public shared func downVote(messageId : Nat) : async Result.Result<(), Text> {
    let messageResult = wall.get(messageId);
    switch (messageResult) {
      case (null) {
        return #err("Message not found2");
      };
      case (?ok) {
        let voteDown : Message = {
          content = ok.content;
          vote = ok.vote - 1;
          creator = ok.creator;
        };

        wall.put(messageId, voteDown);
        return #ok(());
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    var buffer = Buffer.Buffer<Message>(0);
    for (message in wall.vals()) {
      buffer.add(message);
    };
    return Buffer.toArray(buffer);
  };

  // Get all messages ordered by votes
  public query func getAllMessagesRanked() : async [Message] {
    var messages = Buffer.Buffer<Message>(0);

    func compare(messageA : Message, messageB : Message) : Order.Order {
      switch (Int.compare(messageA.vote, messageB.vote)) {
        case (#greater) {
          return #less;
        };
        case (#less) {
          return #greater;
        };
        case (_) {
          return #equal;
        };
      };
    };
    for (message in wall.vals()) {
      messages.add(message);

    };

    messages.sort(compare);

    return Buffer.toArray(messages);

  };
};
