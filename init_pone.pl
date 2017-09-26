% Limitations of the program:
%
% - It is not possible to delete a hypothesis or rule after creating it.
%
% - You can't change the nature of the goal or a rule after creating it. For example,
%   if the goal was conjunctive when created, it is not possible to change it anymore without starting all over again.
%   The same is valid for conjunctive and disjunctive rules.
%
% - It is not possible to change the name of a rule, hypothesis or goal after creating it, and each name must be unique.
%   You are allowed though to change the CF of a rule or hypothesis, or the threshold of the goal.
%   Just make sure you are coherent: if you created a rule with assert_bb_rule(bb_and(hyp1,hyp2),goal,0.9)
%   you must use the same predicate, in the same order, to change its CF. So, for example, assert_bb_rule(bb_and(hyp1,hyp2),goal,0.6).
%   Attempts like assert_bb_rule(bb_and(hyp2,hyp1),goal,0.6) or assert_bb_rule(hyp1,goal,0.6) would just be ignored by the program.
%   
% - Initial CF of the goal is always assumed to be zero, and can't be edited by the user.


% The following predicates are dynamic. In other words, they can be edited using assert/1 and retractall/1 during runtime.
:- dynamic updated/1.
:- dynamic printed/1.
:- dynamic lastNodeID/1.
:- dynamic lastRuleID/1.
:- dynamic nodeHasCF/2.
:- dynamic isNamed/2.
:- dynamic isUnder/2.
:- dynamic nodeHasCF/2.
:- dynamic ruleHasCF/2.
:- dynamic hasThreshold/2.
:- dynamic rule/3.
:- dynamic isAndRule/1.
:- dynamic isOrRule/1.
:- dynamic isAndGoal/0.
:- dynamic isOrGoal/0.
:- dynamic firstTime/1.


% Every node (goal or hypothesis) and rule has an unique ID.
lastNodeID(0).
lastRuleID(0).


% After adding the goal, the program asks for the first hypothesis or rule. Since this only happens in the first time, this predicate
% is edited to firstTime(0) after first assertion. This is just a simple tweak for the interface.
firstTime(1).


% Program is initiated automatically as soon as Prolog starts.
:- initialization(initiate).


% Function called to initialize the program.
initiate:-
	nl,
	writeln('Please enter the goal for the brainstorming process and the termination threshold. Below are some examples:'),
	nl,
	writeln('    assert_bb_goal(increaseSales, 0.8).'),
	writeln('    assert_bb_goal(bb_and(increaseSales, decreaseCosts), 0.5).'),
	writeln('    assert_bb_goal(bb_or(increaseSales, decreaseCosts), 0.9).'),
	nl,
	nl,
	read(Predicate),		% There's no effort to parse the input. Whatever the user enters, is attempted by the program.		
	Predicate.


% After adding the goal:
firstHypothesis:-
	retractall(firstTime(_)),	% Edit firstTime(1) to firstTime(0) so this predicate is only called once.
	assert(firstTime(0)),
	nl,
	nl,
	writeln('Please enter the first hypothesis or rule. Below are some examples:'),
	nl,
	writeln('    assert_bb_hypothesis(moreAdvertising, 1.0).'),
	writeln('    assert_bb_rule(moreAdvertising, increaseSales, 0.5).'),
	writeln('    assert_bb_rule(bb_or(moreAdvertising, moreStores),decreaseCosts, -0.6).'),
	nl,
	nl,
	read(Predicate),		% Again, there's no effort to parse the input. Whatever the user enters, is attempted by the program.		
	Predicate.


% After adding the first hypothesis or rule, this is the predicate called to add more nodes or rules while the threshold has not been surpassed yet:
nextHypothesis:-
	nl,
	writeln('Threshold has not been achieved yet. Please enter another hypothesis or rule, or edit an existing node:'),
	nl,
	nl,
	read(Predicate),		% Again, there's no effort to parse the input. Whatever the user enters, is attempted by the program.		
	Predicate.


% Asserts goal of the brainstorming process, if goal is not conjunctive or disjunctive
assert_bb_goal(Goal,CFthreshold):-
				atom(Goal),					% Checks if Goal is an atom. 'bb_and' and 'bb_or' would fail here.
				not(isNamed(0,Goal)),				% Checks if Goal is not in the database already. If it is, this predicate fails.
				assert(isNamed(0,Goal)),			% Asserts Goal in the database.
				assert(hasThreshold(0,CFthreshold)),		% Asserts Threshold of Goal.
				assert(nodeHasCF(0,0.0)),			% Asserts CF of Goal, always assumed to be zero.
				updateTree.					% Calls predicate to update tree.


% If goal is not conjunctive or disjunctive, but already exists:
assert_bb_goal(Goal,CFthreshold):-
				atom(Goal),
				isNamed(0,Goal),
				retractall(hasThreshold(0,_)),
				assert(hasThreshold(0,CFthreshold)),		% The only change in the database is that the Threshold is altered.
				updateTree.					% Calls predicate to update tree.


% If goal is conjunctive and does not exist:
assert_bb_goal(bb_and(Goal1,Goal2),CFthreshold):-
					not(isNamed(0,Goal1)),			
					not(isNamed(1,Goal2)),
					assert(isNamed(0,Goal1)),
					assert(isNamed(1,Goal2)),
					assert(hasThreshold(0,CFthreshold)),
					assert(hasThreshold(1,CFthreshold)),
					assert(nodeHasCF(0,0.0)),
					assert(nodeHasCF(1,0.0)),
					assert(isAndGoal),			% Asserts in the database that the goal is conjunctive
					retractall(lastNodeID(_)),
					assert(lastNodeID(1)),			% Since two nodes were created, lastNodeID is updated to 1
					updateTree.				% Calls predicate to update tree.


% If goal is conjunctive and already exists:
assert_bb_goal(bb_and(Goal1,Goal2),CFthreshold):-
					isNamed(0,Goal1),			
					isNamed(1,Goal2),
					retractall(hasThreshold(0,_)),
					retractall(hasThreshold(1,_)),
					assert(hasThreshold(0,CFthreshold)),	% The only change in the database is that the Threshold is altered.
					assert(hasThreshold(1,CFthreshold)),
					updateTree.				% Calls predicate to update tree.


% If goal is disjunctive and does not exist yet:
assert_bb_goal(bb_or(Goal1,Goal2),CFthreshold):-
					not(isNamed(0,Goal1)),			
					not(isNamed(1,Goal2)),
					assert(isNamed(0,Goal1)),
					assert(isNamed(1,Goal2)),
					assert(hasThreshold(0,CFthreshold)),
					assert(hasThreshold(1,CFthreshold)),
					assert(nodeHasCF(0,0.0)),
					assert(nodeHasCF(1,0.0)),
					assert(isOrGoal),			% Asserts in the database that the goal is disjunctive
					retractall(lastNodeID(_)),
					assert(lastNodeID(1)),
					updateTree.				% Calls predicate to update tree.


% If goal is disjunctive and already exists:
assert_bb_goal(bb_or(Goal1,Goal2),CFthreshold):-
					isNamed(0,Goal1),			
					isNamed(1,Goal2),
					retractall(hasThreshold(0,_)),
					retractall(hasThreshold(1,_)),
					assert(hasThreshold(0,CFthreshold)),	% The only change in the database is that the Threshold is altered.
					assert(hasThreshold(1,CFthreshold)),
					updateTree.				% Calls predicate to update tree.	


% If hypothesis does not exist yet:
assert_bb_hypothesis(Hypothesis,CF):-
				not(isNamed(_,Hypothesis)),		% Checks if hypothesis exists.	
				lastNodeID(X),				% Gets ID of last node created and increments it by one.
				NewID is X+1,
				assert(isNamed(NewID,Hypothesis)),	% Saves node in the database with respective name
				assert(nodeHasCF(NewID,CF)),		% Saves CF of node
				retractall(lastNodeID(_)),
				assert(lastNodeID(NewID)),		% Updates lastNodeID
				updateTree.				% Calls predicate to update tree.


% If hypothesis already exists:
assert_bb_hypothesis(Hypothesis,CF):-
				isNamed(ID,Hypothesis),
				retractall(nodeHasCF(ID,_)),		
				assert(nodeHasCF(ID,CF)),		% The only change is that the CF of the node is altered.
				updateTree.				% Calls predicate to update tree.


% When the user enter a rule that involves at least one hypothesis that has not been previously created,
% the program must automatically create it. The only difference between assert_bb_hypothesis and assert_bb_hypothesis2
% is that the predicate updateTree/0 is not called in the end.
assert_bb_hypothesis2(Hypothesis,CF):-
				lastNodeID(X),				% No need to check if node exists, since it was already done.
				NewID is X+1,
				assert(isNamed(NewID,Hypothesis)),
				assert(nodeHasCF(NewID,CF)),
				retractall(lastNodeID(_)),
				assert(lastNodeID(NewID)).


% If rule is not conjunctive or disjunctive, and both LHS and RHS already exist:
assert_bb_rule(LHS,RHS,CF):-
			atom(LHS),				% Checks if LHS is an atom. 'bb_and' and 'bb_or' would fail here.
			isNamed(O,LHS),				% Checks if LHS and RHS already exist, and gets their IDs.
			isNamed(K,RHS),
			not(rule(_,O,K)),			% Checks if rule does not exist yet.
			lastRuleID(X),				% Gets lastRuleID used and increments it by one.
			NewID is X+1,
			isNamed(Y,LHS),
			isNamed(Z,RHS),
			assert(rule(NewID,Y,Z)),		% Asserts rule in the database, with respective LHS and RHS.
			assert(ruleHasCF(NewID,CF)),		% Asserts CF of rule.
			retractall(lastRuleID(_)),
			assert(lastRuleID(NewID)),		% Updates lastRuleID.
			updateTree.				% Calls predicate to update tree.


% If rule is not conjunctive or disjunctive, and already exists (obviously, the LHS and RHS already exist as well):
assert_bb_rule(LHS,RHS,CF):-
			atom(LHS),
			isNamed(O,LHS),
			isNamed(K,RHS),
			rule(ID,O,K),
			not(isAndRule(ID)),
			not(isOrRule(ID)),
			retractall(ruleHasCF(ID,_)),
			assert(ruleHasCF(ID,CF)),		% Only change in the database is that the Cf of the rule is altered.
			updateTree.				% Calls predicate to update tree.


% If rule is not conjunctive or disjunctive, LHS does not exist yet, but RHS already exists:
assert_bb_rule(LHS,RHS,CF):-
			atom(LHS),
			not(isNamed(_,LHS)),
			isNamed(_,RHS),
			assert_bb_hypothesis2(LHS,0.0),		% Adds LHS to database, assuming its CF to be zero, before adding rule to the database.
			lastRuleID(O),
			NewRuleID is O+1,
			isNamed(Z,RHS),
			isNamed(A,LHS),
			assert(rule(NewRuleID,A,Z)),
			assert(ruleHasCF(NewRuleID,CF)),
			retractall(lastRuleID(_)),
			assert(lastRuleID(NewRuleID)),
			updateTree.				% Calls predicate to update tree.


% If rule is not conjunctive or disjunctive, LHS already exists, but RHS does not exist yet:
assert_bb_rule(LHS,RHS,CF):-
			atom(LHS),
			isNamed(_,LHS),
			not(isNamed(_,RHS)),
			assert_bb_hypothesis2(RHS,0.0),		% Adds RHS to database, assuming its CF to be zero, before adding rule to the database.
			lastRuleID(O),
			NewRuleID is O+1,
			isNamed(Z,LHS),
			isNamed(A,RHS),
			assert(rule(NewRuleID,Z,A)),
			assert(ruleHasCF(NewRuleID,CF)),
			retractall(lastRuleID(_)),
			assert(lastRuleID(NewRuleID)),
			updateTree.				% Calls predicate to update tree.


% If rule is not conjunctive or disjunctive, LHS and RHS do not exist yet:
assert_bb_rule(LHS,RHS,CF):-
			atom(LHS),
			not(isNamed(_,LHS)),
			not(isNamed(_,RHS)),
			assert_bb_hypothesis2(RHS,0.0),		% Adds RHS and LHS to database, assuming their CFs to be zero, before adding rule to the database.
			assert_bb_hypothesis2(LHS,0.0),
			lastRuleID(O),
			NewRuleID is O+1,
			isNamed(Z,LHS),
			isNamed(A,RHS),
			assert(rule(NewRuleID,Z,A)),
			assert(ruleHasCF(NewRuleID,CF)),
			retractall(lastRuleID(_)),
			assert(lastRuleID(NewRuleID)),
			updateTree.				% Calls predicate to update tree.
			
			

% Rule is conjunctive and does not exist yet. LHS1, LHS2 and RHS already exist.
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				isNamed(O,LHS1),		% Checks for existence of hypotheses.
				isNamed(_,LHS2),
				isNamed(K,RHS),
				not(rule(_,O,K)),		% Checks for non-existence of rule.
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),	% Asserts rule between LHS1 and RHS with ID.
				assert(rule(NewID,R,Z)),	% Asserts rule between LHS1 and RHS with same ID.
				assert(ruleHasCF(NewID,CF)),	% Asserts CF of rule.
				assert(isAndRule(NewID)),	% Asserts that rule is conjunctive.
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.			% Calls predicate to update tree.


% Rule is conjunctive and already exists (LHS1,LHS2 and RHS already exist, by definition):
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				isNamed(O,LHS1),		% LHS1 and LHS2 must be in the same order when rule was created
				isNamed(_,LHS2),
				isNamed(K,RHS),
				rule(ID,O,K),			% Checks if rule already exists.
				isAndRule(ID),			% Checks if rule is conjunctive.
				retractall(ruleHasCF(ID,_)),
				assert(ruleHasCF(ID,CF)),	% Only change in the database is that the CF of rule is altered;
				updateTree.			% Calls predicate to update tree.
		
		
% Rule is conjunctive. LHS1 does not exist yet. LHS2 and RHS already exist:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				isNamed(_,LHS2),
				isNamed(_,RHS),
				assert_bb_hypothesis2(LHS1,0.0),	% Creates LHS1 before asserting rule.
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.
				
				
% Rule is conjunctive. LHS1 and LHS2 do not exist yet. RHS already exists:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				not(isNamed(_,LHS2)),
				isNamed(_,RHS),
				assert_bb_hypothesis2(LHS1,0.0),	% Creates LHS1 and LHS2 before asserting rule.
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.
	
	
% Rule is conjunctive. LHS1, LHS2 and RHS do not exist yet:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				not(isNamed(_,LHS2)),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),		% Creates LHS1, LHS2 and RHS before asserting rule.
				assert_bb_hypothesis2(LHS1,0.0),
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.
				
				
% Rule is conjunctive. LHS1 and RHS do not exist yet. LHS2 already exists:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				isNamed(_,LHS2),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),		% Creates LHS1 and RHS before asserting rule.
				assert_bb_hypothesis2(LHS1,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.


% Rule is conjunctive. LHS2 does not exist yet. LHS1 and RHS already exist:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				isNamed(_,LHS1),
				not(isNamed(_,LHS2)),
				isNamed(_,RHS),
				assert_bb_hypothesis2(LHS2,0.0),	% Creates LHS2 before asserting rule.
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.


% Rule is conjunctive. LHS2 and RHS do not exist yet. LHS1 already exists:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				isNamed(_,LHS1),
				not(isNamed(_,LHS2)),			% Creates LHS2 and RHS before asserting rule.
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.
				
				
% Rule is conjunctive. RHS does not exist yet. LHS1 and LHS2 already exist:
assert_bb_rule(bb_and(LHS1,LHS2),RHS,CF):-
				isNamed(_,LHS1),
				isNamed(_,LHS2),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),		% Creates RHS before asserting rule.
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isAndRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.				% Calls predicate to update tree.


% Rule is disjunctive and does not exist yet. LHS1, LHS2 and RHS already exist:				
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				isNamed(O,LHS1),
				isNamed(_,LHS2),
				isNamed(K,RHS),
				not(rule(_,O,K)),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.


% Rule is disjunctive and already exists:
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				isNamed(O,LHS1),
				isNamed(_,LHS2),
				isNamed(K,RHS),
				rule(ID,O,K),
				isOrRule(ID),
				retractall(ruleHasCF(ID,_)),
				assert(ruleHasCF(ID,CF)),
				updateTree.
				
				
% Rule is disjunctive. LHS1 does not exist yet. LHS2 and RHS already exist:			
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				isNamed(_,LHS2),
				isNamed(_,RHS),
				assert_bb_hypothesis2(LHS1,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.

	
% Rule is disjunctive. LHS1 and LHS2 do not exist yet. RHS already exists:			
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				not(isNamed(_,LHS2)),
				isNamed(_,RHS),
				assert_bb_hypothesis2(LHS1,0.0),
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.
				
				
% Rule is disjunctive. LHS1 and RHS do not exist yet. LHS2 already exists:				
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				isNamed(_,LHS2),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),
				assert_bb_hypothesis2(LHS1,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.
			
			
% Rule is disjunctive. LHS1, LHS2 and RHS do not exist yet:			
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				not(isNamed(_,LHS1)),
				not(isNamed(_,LHS2)),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),
				assert_bb_hypothesis2(LHS1,0.0),
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.
				
				
% Rule is disjunctive. LHS2 does not exist yet. LHS1 and RHS already exist:				
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				isNamed(_,LHS1),
				not(isNamed(_,LHS2)),
				isNamed(_,RHS),
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.
				
				
% Rule is disjunctive. LHS2 and RHS do not exist yet. LHS1 already exists:			
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				isNamed(_,LHS1),
				not(isNamed(_,LHS2)),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),
				assert_bb_hypothesis2(LHS2,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.
				
				
% Rule is disjunctive. RHS does not exist yet. LHS1 ans LHS2 already exist:			
assert_bb_rule(bb_or(LHS1,LHS2),RHS,CF):-
				isNamed(_,LHS1),
				isNamed(_,LHS2),
				not(isNamed(_,RHS)),
				assert_bb_hypothesis2(RHS,0.0),
				lastRuleID(X),
				NewID is X+1,
				isNamed(Y,LHS1),
				isNamed(R,LHS2),
				isNamed(Z,RHS),
				assert(rule(NewID,Y,Z)),
				assert(rule(NewID,R,Z)),
				assert(ruleHasCF(NewID,CF)),
				assert(isOrRule(NewID)),
				retractall(lastRuleID(_)),
				assert(lastRuleID(NewID)),
				updateTree.
	
	
% Predicate called to update tree = propagate belief. For a high level explanation, please see report.
updateTree:-
	retractall(updated1(_)),		% Every node is not updated = red.
	retractall(updated2(_,_)),		% Every rule is not updated = red.
	retractall(nodeHasUpdatedCF(_,_)),	% Every node starts with original CF, provided by the user or assumed to be zero.
	restartCF,				% Calls restartCF/0 to initialize temporary CF of each node to its initial value.
	isNamed(ID,_),				% Finds node with no parents.
	not(rule(_,ID,_)),
	updateCF(ID).				% Calls predicate to update this node.
	
	
% After updating all nodes with no parents, the predicate above will fail. Prolog will then attempt this predicate.
% Prints table with updated CFs for every node.
updateTree:-
	nl,
	format('+~`-t~84|+ ~n', []),
	format('| ~s~t~5|| ~s~t~56|| ~s~t~84|| ~n',['ID', 'Name', 'CF']),	% Creates head of the table.
	format('+~`-t~84|+ ~n', []),
	retractall(printed(_)),							% This states that no node has been printed yet.
	printTable.								% Calls predicate to print all nodes, one by one.
	
	
% Initializes temporary CF of each node to its initial value. This temporary CF will be the one updated and printed on the table.
% This allows the program not to alter the original CF provided by the user or assumed to be zero.
restartCF:-
	nodeHasCF(X,Y),
	not(nodeHasUpdatedCF(X,_)),
	assert(nodeHasUpdatedCF(X,Y)),
	restartCF.

restartCF.


% Finds a node that has not been printed yet, then prints it.
printTable:-
	nl,
	isNamed(X,Y),
	not(printed(X)),						% Checks if node hasn't been printed.
	nodeHasUpdatedCF(X,Z),						% Gets temporary (updated) CF of node.
	atom_number(X1,X),
	atom_number(Z1,Z),
	format('| ~s~t~5|| ~s~t~56|| ~s~t~84|| ~n',[X1, Y, Z1]),	% Prints ID, name and CF of node in the table format.
	assert(printed(X)),						% Saves in the database that node has been printed.
	printTable.							% Prints next node until there are no more nodes not printed.
	
	
% When all nodes have been printed:	
printTable:-
	not(isAndGoal),									% If goal is not conjunctive or disjunctive.
	not(isOrGoal),
	nodeHasUpdatedCF(0,X),								% Gets updated CF of goal.
	hasThreshold(0,CFthreshold),							% Gets threshold of goal.
	X >= CFthreshold,								% If it has been surpassed:
	nl,
	print('Threshold has been achieved. Program will be terminated in 5 seconds'),
	nl,
	sleep(5),									% Wait 5 second then close program.
	halt.
	
	
% If goal is conjunctive:	
printTable:-
	isAndGoal,
	nodeHasUpdatedCF(0,X),
	nodeHasUpdatedCF(1,Y),
	hasThreshold(0,CFthreshold),				
	testForMin(X,Y,Minimum),
	Minimum >= CFthreshold,								% Compares threshold to minimum CF between both goals
	nl,
	print('Threshold has been achieved. Program will be terminated in 5 seconds'),
	nl,
	sleep(5),
	halt.


% If goal is disjunctive:
printTable:-
	isOrGoal,
	nodeHasUpdatedCF(0,X),
	nodeHasUpdatedCF(1,Y),
	hasThreshold(0,CFthreshold),
	testForMax(X,Y,Maximum),
	Maximum >= CFthreshold,								% Compares threshold to maximum CF between both goals
	nl,
	print('Threshold has been achieved. Program will be terminated in 5 seconds'),
	nl,
	sleep(5),
	halt.
	
	
% If it gets here, threshold hasn't been satisfied. If it is not the first time your adding a hypothesis or rule:	
printTable:-
	firstTime(0),
	nextHypothesis.


% If it is the first time:
printTable:-
	firstTime(1),
	firstHypothesis.
	
	
% Predicate to update CF of a node:	
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),			% Gets temporary CF of node in question.
		rule(RuleID,Y,Node),				% Finds child of node.
		not(isAndRule(RuleID)),				% If rule between node in question and child is not conjunctive or disjunctive,
		not(isOrRule(RuleID)),
		updated1(Y),					% and the child's CF was already updated = child node is green,
		not(updated2(Y,Node)),				% and the rule between node in question and child has not been updated = rule is red,
		nodeHasUpdatedCF(Y,J),
		ruleHasCF(RuleID,Z),
		W is J*Z,
		X > 0,						% CF of parent, and CF of rule and child are positive
		W > 0,
		NewCF is X + W*(1 - X),				% then calculate new value for CF of node in question.
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),		% Update temporary CF of node.
		assert(updated2(Y,Node)),			% Assert that rule between node in question and child has been updated = rule is green.
		updateCF(Node).					% Tries to update itself again. It means that it either looks for other children, if node
								% was updated. Or program moves to a child whose CF has not been updated yet.
		
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		not(isAndRule(RuleID)),
		not(isOrRule(RuleID)),
		updated1(Y),
		not(updated2(Y,Node)),
		nodeHasUpdatedCF(Y,J),
		ruleHasCF(RuleID,Z),
		W is J*Z,
		X < 0,						% CF of parent, and CF of rule and child are negative
		W < 0,
		NewCF is X + W*(1 + X),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		updateCF(Node).
	

updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		not(isAndRule(RuleID)),
		not(isOrRule(RuleID)),
		updated1(Y),
		not(updated2(Y,Node)),
		nodeHasUpdatedCF(Y,J),
		ruleHasCF(RuleID,Z),
		W is J*Z,					% Else...
		testForMin(abs(X),abs(W),Minimum),
		NewCF is (X + W)/(1 - Minimum),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		updateCF(Node).
		

updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		isAndRule(RuleID),				% If rule between parent node and children is conjunctive,
		rule(RuleID,R,Node),
		R > Y,
		updated1(Y),					% both children must have updated CFs. The rest of the process is similar.
		updated1(R),
		not(updated2(Y,Node)),
		not(updated2(R,Node)),
		nodeHasUpdatedCF(Y,J),
		nodeHasUpdatedCF(R,V),
		testForMin(J,V,Minimum), 			% Since rule is conjunctive, minimum CF is considered.
		ruleHasCF(RuleID,Z),
		W is Minimum*Z,
		X > 0,
		W > 0,
		NewCF is X + W*(1 - X),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		assert(updated2(R,Node)),
		updateCF(Node).					% Tries to update itself again. It means that it either looks for other children, if node
								% was updated. Or program moves to a child whose CF has not been updated yet.
		
		
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		isAndRule(RuleID),
		rule(RuleID,R,Node),
		R > Y,
		updated1(Y),
		updated1(R),
		not(updated2(Y,Node)),
		not(updated2(R,Node)),
		nodeHasUpdatedCF(Y,J),
		nodeHasUpdatedCF(R,V),
		testForMin(J,V,Minimum), 
		ruleHasCF(RuleID,Z),
		W is Minimum*Z,
		X < 0,
		W < 0,
		NewCF is X + W*(1 + X),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		assert(updated2(R,Node)),
		updateCF(Node).
		
		
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		isAndRule(RuleID),
		rule(RuleID,R,Node),
		R > Y,
		updated1(Y),
		updated1(R),
		not(updated2(Y,Node)),
		not(updated2(R,Node)),
		nodeHasUpdatedCF(Y,J),
		nodeHasUpdatedCF(R,V),
		testForMin(J,V,Minimum), 
		ruleHasCF(RuleID,Z),
		W is Minimum*Z,
		testForMin(abs(X),abs(W),Minimum2),
		NewCF is (X + W)/(1 - Minimum2),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		assert(updated2(R,Node)),
		updateCF(Node).
		
		
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		isOrRule(RuleID),				% If rule between parent node and children is disjunctive,
		rule(RuleID,R,Node),
		R > Y,
		updated1(Y),					% both children must have updated CFs. The rest of the process is similar.
		updated1(R),
		not(updated2(Y,Node)),
		not(updated2(R,Node)),
		nodeHasUpdatedCF(Y,J),
		nodeHasUpdatedCF(R,V),
		testForMax(J,V,Maximum),			% Since rule is disjunctive, maximum CF is considered. 
		ruleHasCF(RuleID,Z),
		W is Maximum*Z,
		X > 0,
		W > 0,
		NewCF is X + W*(1 - X),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		assert(updated2(R,Node)),
		updateCF(Node).
		
		
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		isOrRule(RuleID),
		rule(RuleID,R,Node),
		R > Y,
		updated1(Y),
		updated1(R),
		not(updated2(Y,Node)),
		not(updated2(R,Node)),
		nodeHasUpdatedCF(Y,J),
		nodeHasUpdatedCF(R,V),
		testForMax(J,V,Maximum), 
		ruleHasCF(RuleID,Z),
		W is Maximum*Z,
		X < 0,
		W < 0,
		NewCF is X + W*(1 + X),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		assert(updated2(R,Node)),
		updateCF(Node).
		
		
updateCF(Node):-
		nodeHasUpdatedCF(Node,X),
		rule(RuleID,Y,Node),
		isOrRule(RuleID),
		rule(RuleID,R,Node),
		R > Y,
		updated1(Y),
		updated1(R),
		not(updated2(Y,Node)),
		not(updated2(R,Node)),
		nodeHasUpdatedCF(Y,J),
		nodeHasUpdatedCF(R,V),
		testForMax(J,V,Maximum), 
		ruleHasCF(RuleID,Z),
		W is Maximum*Z,
		testForMin(abs(X),abs(W),Minimum),
		NewCF is (X + W)/(1 - Minimum),
		retractall(nodeHasUpdatedCF(Node,_)),
		assert(nodeHasUpdatedCF(Node,NewCF)),
		assert(updated2(Y,Node)),
		assert(updated2(R,Node)),
		updateCF(Node).


updateCF(Node):-
		rule(_,Y,Node),			% If parent node has a child
		not(updated1(Y)),		% that hasn't been updated yet,
		updateCF(Y),			% then first update CF of child node.
		updateCF(Node).			% Only after, try to update itself again, since child is now updated.
		
		
updateCF(Node):-
		assert(updated1(Node)),		% If it gets to this predicate, then it is a node with no children, and it's automatically updated.
		rule(_,Node,X),			
		updateCF(X).			% Then the program tries to update its parent.
		
		
% Predicate to get minimum between to numbers, X and Y		
testForMin(X,Y,Minimum):-
			X =< Y,
			Minimum is X.
			
testForMin(X,Y,Minimum):-
			X > Y,
			Minimum is Y.
			
			
% Predicate to get maximum between to numbers, X and Y				
testForMax(X,Y,Maximum):-
			X =< Y,
			Maximum is Y.
			
testForMax(X,Y,Maximum):-
			X > Y,
			Maximum is X.