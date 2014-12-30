//
//  SuggestionsManager.h
//  BabyName
//
//  Created by Massimo Peri on 20/11/14.
//  Copyright (c) 2014 Massimo Peri. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "Suggestion.h"


@interface SuggestionsManager : NSObject

+ (SuggestionsManager *)sharedManager;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong, readonly) Suggestion *currentSuggestion;

- (NSArray *)fetchedSuggestions;
- (NSArray *)acceptedSuggestions;
- (NSArray *)availableSuggestions;

- (Suggestion *)randomSuggestion;
- (Suggestion *)preferredSuggestion;

- (BOOL)acceptSuggestion:(Suggestion *)suggestion;
- (BOOL)rejectSuggestion:(Suggestion *)suggestion;
- (BOOL)preferSuggestion:(Suggestion *)suggestion;
- (BOOL)unpreferSuggestion:(Suggestion *)suggestion;

- (BOOL)update;
- (BOOL)reset;
- (BOOL)populate;
- (BOOL)save;
- (BOOL)validatePreferredSuggestion;

@end
