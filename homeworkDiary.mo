
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Debug "mo:base/Debug";






// import Order "Order";
// import Array "Array";

actor HomeworkDiary {
    public type Time = Time.Time;

    type Homework =  {
      title: Text;
      description: Text;
      dueDate: Time;
      completed: Bool;
};
     
    let homeworkDiary = Buffer.Buffer <Homework>(10);

    public func addHomework(homework: Homework) : async Nat {
         homeworkDiary.add(homework);
        return homeworkDiary.size() - 1;
    };
   public query func getHomework(homeworkId: Nat): async Result.Result<Homework, Text> {
   
        let result : ?Homework = homeworkDiary.getOpt(homeworkId);

    switch (result) {
        case (null) { #err("Invalid index.") };
        case (?record) { #ok(record) };
    };
    };
    public func updateHomework(homeworkId: Nat, homework: Homework): async Result.Result<(), Text> {
    if (homeworkId >= homeworkDiary.size()) {
        return #err("Invalid homework ID");
    } else {
        homeworkDiary.put(homeworkId, homework);
        return #ok(());
    }
    };
    public func markAsCompleted(homeworkId: Nat): async Result.Result<(), Text> {
        if(homeworkId >= homeworkDiary.size()){
            return #err("Invalid homework ID");
        }else{
            switch(?homeworkDiary.get(homeworkId)){
                case null {#err("Invalid homework ID");};
                case (?homework){
                    let complete:Homework = {
                title=homework.title;
                description=homework.description;
                dueDate= homework.dueDate;
                completed = true;
               
             };
            homeworkDiary.put(homeworkId, complete);
            return #ok(());
                }
            }
            
        };

};
    public func deleteHomework(homeworkId: Nat): async Result.Result<(), Text> {
        if (homeworkId >= homeworkDiary.size()) {
            return #err("Invalid homework ID");
        } else {
            var counter : Nat = 0;
            for(name in homeworkDiary.vals()){
                if(counter == homeworkId){
                    let removed = homeworkDiary.remove(counter);
                    return #ok(());
                };
                counter := counter +1;               
            };
             return #err("Invalid homework ID");
        }
    };
    public query func getAllHomework(): async [Homework] {
        return (Buffer.toArray(homeworkDiary));
    };
    
    public query func getPendingHomework(): async [Homework] {
        let arrayRes = Buffer.Buffer<Homework>(0);


        for (homework in homeworkDiary.vals()) {
            if (not homework.completed) {
              arrayRes.add(homework);
            }
        };
        let result = Buffer.toArray(arrayRes);
        return result;
        };   

     public shared query func searchHomework(searchTerm : Text) : async [Homework] {
      
          let matchingHomeworks = Buffer.Buffer<Homework>(0);

    for(homework in homeworkDiary.vals()) {
        if (Text.contains(homework.title,#text searchTerm) or Text.contains(homework.description,#text searchTerm)) {
            matchingHomeworks.add(homework);
        }
    };

    return Buffer.toArray(matchingHomeworks);
    };
};