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

// --- temp
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
// ---

+ (SuggestionsManager *)sharedManager;

- (NSArray *)fetchedSuggestions;
- (NSArray *)acceptedSuggestions;

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

@end
