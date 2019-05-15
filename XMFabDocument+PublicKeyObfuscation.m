//  CodexFab
//
// XMFabDocument (PublicKeyObfuscation)
//
//  Licensed under CC Attribution License 3.0 <http://creativecommons.org/licenses/by/3.0/>
//
// Based on CocoaFob by Gleb Dolgich
// <http://github.com/gbd/cocoafob/tree/master>
//
//  Created by Mantis on 10/07/09.
//  Copyright 2009 MachineCodex Software Australia. All rights reserved.
// <http://www.machinecodex.com>


#import "XMFabDocument.h"

//TODO: Make sure that \n newline characters are not broken across lines.trin


@implementation XMFabDocument (PublicKeyObfuscation) 

- (IBAction) showObfusactorPanel:(id)sender {
	
	[self generateObfuscatedCode:self];
    [self.windowForSheet beginSheet:obfuscatorPanel completionHandler:^(NSModalResponse returnCode) {
        [self closeObfusactorPanel:self];
    }];
}

- (IBAction) closeObfusactorPanel:(id)sender {
	
	[obfuscatorPanel orderOut:self];
	[NSApp endSheet:obfuscatorPanel];
}

- (IBAction) codeTypeChanged:(id)sender
{
    [self generateObfuscatedCode:nil];
}

- (void)generateObfuscatedCode:(id)sender {
	
	NSString *pubKey = [[self pem] valueForKey:@"publicKey"];
	if(pubKey)
        self.obfuscatedPublicKey = [self obfuscatedCocoaCodeForPublicKey:pubKey];
}

- (NSString *)obfuscatedCocoaCodeForPublicKey:(NSString*)publicKeyString {

	//Generates a block of Cocoa code that assembles the public key
	//from variable-length substrings into an NSMutableString
	
	// Define some Cocoa-code-wrapper strings for substitution
	NSString *openmsg = @"NSMutableString *pkb64 = [NSMutableString string];\n";
	NSString *closeMsg = @"NSString *publicKey = [NSString stringWithString:pkb64];\n";
	NSString *pkb64FragOpen = @"[pkb64 appendString:@\"";
	NSString *pkb64FragClose =  @"\"];\n";
    
    
    //swift or objC?
    NSInteger obfuscatorIndex = 0;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"codeType"] != nil)
        obfuscatorIndex = [defaults integerForKey:@"codeType"];
    
    if (obfuscatorIndex == 1)
    {
        openmsg = @"let pkb64:NSMutableString = NSMutableString()\n";
        closeMsg = @"let publicKey = pkb64 as String";
        pkb64FragOpen = @"pkb64.append(\"";
        pkb64FragClose =  @"\"];\n";
    }
    
	
	//Container for the Cocoa code-as-text
	NSMutableString *pkb64Fragmented = [NSMutableString string];
	
	//Container for the publicKeyString
	NSMutableString *tempKey = [NSMutableString string];

	//remove first & last lines
	NSArray *lines = [publicKeyString componentsSeparatedByString:@"\n"];
	int i, cnt = (int)[lines count];
	for (i=1; i < cnt -2; i++) {
		[tempKey appendString:[NSString stringWithFormat:@"%@\n",[lines objectAtIndex:i]]];
	}
	
	// escape newlines (so they will display as textual characters)
	[tempKey replaceOccurrencesOfString:@"\n" 
							 withString:@"\\n" 
								options:NSLiteralSearch 
								  range:NSMakeRange(0, [tempKey length])];
	
	int length = (int)[tempKey length];
	
	// define min & max substring lengths - these could be exposed in the gui
	int maxStringLength =  (length/8);
	int minStringLength =  3;
	
	// init rand() 
	srand((int)time(NULL));
	
	// break up the string into random length chunks
	int firstIndex = 0;
	while (firstIndex < length) {
		// walk through the key from start to end, biting off random-length
		// chunks and appending them by format to the Cocoa-code-string 
		int tlength = ( rand() % maxStringLength ) + minStringLength;
		if(firstIndex + tlength > length) tlength = length - firstIndex;
		NSString *line = [tempKey substringWithRange:NSMakeRange(firstIndex, tlength)];

		if ([line hasSuffix:@"\\"]) { //Make sure our line doesn't end in a backslash as this may split a newline token
			
			tlength += 2;
			line = [tempKey substringWithRange:NSMakeRange(firstIndex, tlength)];
		}
			
		[pkb64Fragmented appendString:[NSString stringWithFormat:@"%@%@%@",pkb64FragOpen,line,pkb64FragClose]];
		firstIndex += tlength;
	}

	return [NSString stringWithFormat:@"%@%@%@",openmsg,pkb64Fragmented,closeMsg];

}


@end
