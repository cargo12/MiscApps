//
//  AppDelegate.m
//  UninstallPKGDiagnosisTool
//
//  Created by CoreCode on 09.01.13.
/*	Copyright (c) 2016 CoreCode
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//

#import "AppDelegate.h"
#import "JMEmailSender.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	cc = [CoreLib new];

	[self.progress startAnimation:self];
	[self.progress setUsesThreadedAnimation:YES];
	[self performSelector:@selector(perform) withObject:nil afterDelay:0.1];
}

- (void)perform
{

	tmpPath = [makeTempFolder() stringByAppendingString:@"/"];
	tmpURL = tmpPath.fileURL;
	asl_NSLog_debug(@"%@", tmpPath);

	
    [fileManager copyItemAtPath:@"/Library/Logs/DiagnosticReports/"
                         toPath:[tmpPath stringByAppendingString:@"DRG"] error:NULL];
    
    [fileManager copyItemAtPath:[@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath]
						 toPath:[tmpPath stringByAppendingString:@"DR"] error:NULL];



	{
		NSURL *path = @"~/Library/Preferences/".expanded.fileURL;
		for (NSString *p in [path.path.dirContents filteredUsingPredicateString:@"self BEGINSWITH[cd] 'com.corecode'"])
			[fileManager copyItemAtURL:[path add:p] toURL:[tmpURL add:p] error:NULL];
	}


	[fileManager copyItemAtPath:@"/Library/LaunchDaemons/com.corecode.UninstallPKGDeleteHelper.plist"
						 toPath:[tmpPath stringByAppendingString:@"LaunchDaemonscom.corecode.UninstallPKGDeleteHelper.plist"] error:NULL];
	[fileManager copyItemAtPath:@"/Library/PrivilegedHelperTools/com.corecode.UninstallPKGDeleteHelper"
						 toPath:[tmpPath stringByAppendingString:@"PrivilegedHelperToolscom.corecode.UninstallPKGDeleteHelper"] error:NULL];



	[tmpURL add:@"LaunchDaemonsDir"].contents = [@[@"/bin/ls", @"-la", @"/Library/LaunchDaemons/"] runAsTask].data;
	[tmpURL add:@"PrivilegedHelperToolsDir"].contents = [@[@"/bin/ls", @"-la", @"/Library/PrivilegedHelperTools/"] runAsTask].data;

	[tmpURL add:@"ps"].contents = [@[@"/bin/ps", @"ax"] runAsTask].data;
	[tmpURL add:@"loginItems"].contents = [self loginItems].data;
	[tmpURL add:@"system_profiler"].contents = [@[@"/usr/sbin/system_profiler", @"-xml", @"-detailLevel", @"full"] runAsTask].data;
	[tmpURL add:@"ioreg"].contents = [@[@"/usr/sbin/ioreg", @"-l", @"-w", @"0"] runAsTask].data;
	[tmpURL add:@"diskutil"].contents = [@[@"/usr/sbin/diskutil", @"list"] runAsTask].data;
	for (int i = 0; i < 16; i++)
		[tmpURL add:makeString(@"diskutil%i", i)].contents = [@[@"/usr/sbin/diskutil", @"info", makeString(@"disk%i", i)] runAsTask].data;



	// Create authorization reference
	OSStatus status;
	AuthorizationRef authorizationRef;

	// AuthorizationCreate and pass NULL as the initial
	// AuthorizationRights set so that the AuthorizationRef gets created
	// successfully, and then later call AuthorizationCopyRights to
	// determine or extend the allowable rights.
	// http://developer.apple.com/qa/qa2001/qa1172.html
	status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
	if (status != errAuthorizationSuccess)
	{
		alert_apptitled(@"Can't proceed to get diagnosis without admin rights", @"OK", nil, nil);
		exit(1);
	}

	// kAuthorizationRightExecute == "system.privilege.admin"
	AuthorizationItem right = {kAuthorizationRightExecute, 0, NULL, 0};
	AuthorizationRights rights = {1, &right};
	AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |
	kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;

	// Call AuthorizationCopyRights to determine or extend the allowable rights.
	status = AuthorizationCopyRights(authorizationRef, &rights, NULL, flags, NULL);
	if (status != errAuthorizationSuccess)
	{
		alert_apptitled(@"AuthorizationCopyRights failed", @"OK", nil, nil);
		exit(1);
	}


	{
		char *tool = "/usr/bin/tar";
		char *args[] = {"cvf", [tmpURL add:@"system.log.tgz"].path.UTF8String, "/private/var/log/system.log", NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:@"tarlogresult"].contents = result.data;
		}
	}
	{
		char *tool = "/usr/bin/tar";
		char *args[] = {"cvf", [tmpURL add:@"com.apple.xpc.launchd.tgz"].path.UTF8String, "/var/db/com.apple.xpc.launchd", NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:@"tarlaunchdresult"].contents = result.data;
		}
	}
	{
		char *tool = "/bin/launchctl";
		char *args[] = {"print", "system/", NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:@"launchctlprintsystem"].contents = result.data;
		}
	}
	{
		char *tool = "/bin/launchctl";
		char *args[] = {"print-disabled", "system", NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:@"launchctlprintdisabledsystem"].contents = result.data;
		}
	}
	{
		char *tool = "/bin/launchctl";
		char *args[] = {"print-cache", NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:@"launchctlprintcache"].contents = result.data;
		}
	}
	{
		char *tool = "/bin/launchctl";
		char *args[] = {"print", "system/com.corecode.UninstallPKGDeleteHelper", NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:@"launchctlprintsystemuninstallpkg"].contents = result.data;
		}
	}
	{
		NSString *idStr = 	[@[@"/usr/bin/id", @"-u"] runAsTask];
		NSNumber *idNum = 	@(idStr.integerValue);

		char *tool = "/bin/launchctl";
		char *args[] = {"print", makeString(@"user/%li", (long)idNum.integerValue).UTF8String, NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:makeString(@"launchctlprintuser%li", (long)idNum.integerValue)].contents = result.data;
		}
	}
	{
		NSString *idStr = 	[@[@"/usr/bin/id", @"-u"] runAsTask];
		NSNumber *idNum = 	@(idStr.integerValue);

		char *tool = "/bin/launchctl";
		char *args[] = {"print", makeString(@"gui/%li", (long)idNum.integerValue).UTF8String, NULL};
		FILE *pipe = NULL;

		status = AuthorizationExecuteWithPrivileges(authorizationRef, tool, kAuthorizationFlagDefaults, args, &pipe);
		if (status != errAuthorizationSuccess)
		{
			alert_apptitled(@"AuthorizationExecuteWithPrivileges failed", @"OK", nil, nil);
			exit(1);
		}
		else
		{
			char myReadBuffer[128];
			NSMutableString *result = makeMutableString();
			for(;;)
			{
				long bytesRead = read(fileno(pipe), myReadBuffer, sizeof (myReadBuffer));
				if (bytesRead < 1)
					break;
				else
					{
    NSString *appendstring = [[NSString alloc] initWithBytes:myReadBuffer length:bytesRead encoding:NSUTF8StringEncoding];
    if (appendstring)
        [result appendString:appendstring];
}
			}
			[tmpURL add:makeString(@"launchctlprintgui%li", (long)idNum.integerValue)].contents = result.data;
		}
	}
	// The only way to guarantee that a credential acquired when you
	// request a right is not shared with other authorization instances is
	// to destroy the credential.  To do so, call the AuthorizationFree
	// function with the flag kAuthorizationFlagDestroyRights.
	// http://developer.apple.com/documentation/Security/Conceptual/authorization_concepts/02authconcepts/chapter_2_section_7.html
	status = AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);






	NSTask *task = [NSTask new];
	[task setLaunchPath:@"/usr/bin/tar"];
	[task setCurrentDirectoryPath:[tmpURL URLByDeletingLastPathComponent].path];
	[task setArguments:@[@"czf", @"CCdiagnosis.tgz", [tmpURL lastPathComponent]]];
	[task launch];
	[task waitUntilExit];




	[self.box1 setHidden:YES];
	[self.box2 setHidden:NO];
}

- (IBAction)send:(id)sender
{
	NSURL *attachment = [[tmpURL URLByDeletingLastPathComponent] add:@"CCdiagnosis.tgz"];

	assert(attachment.fileExists);

	if ([JMEmailSender sendMailWithScriptingBridge:@"hello corecode,\nhelpful files to diagnose product problems are attached.\nbye\n\n"
										   subject:@"CoreCode Diagnose Files"
												to:@"feedback@corecode.io"
										   timeout:60
										attachment:attachment.path] == kSMTPSuccess)
	{
		NSRunAlertPanel(@"Result", @"Sending succeeded. You can look into your Mail.app outbox", @"OK", nil, nil);
	}
	else
	{
		[fileManager copyItemAtURL:attachment
							 toURL:@"~/Desktop/CCdiagnosis.tgz".expanded.uniqueFile.fileURL
							 error:NULL];


		NSRunAlertPanel(@"Result", @"Sending failed. Send the file yourself to <feedback@corecode.io>, it is now on your desktop.", @"OK", nil, nil);
	}

	[fileManager removeItemAtURL:tmpURL error:NULL];
}


- (NSString *)loginItems
{
	UInt32 outSnapshotSeed;
	LSSharedFileListRef list = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	NSMutableString *tmp = [NSMutableString new];

	if (list)
	{
		NSArray *array = (__bridge NSArray *) LSSharedFileListCopySnapshot(list, &outSnapshotSeed);

		if (array)
		{
			for (id item in array)
			{
				CFURLRef url = NULL;
				OSStatus status = LSSharedFileListItemResolve((__bridge LSSharedFileListItemRef)item, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, &url, NULL);

				if (status == noErr)
				{
					[tmp appendFormat:@"item %@\n", [(__bridge NSURL *)url path]];
				}


				if (url != NULL)
					CFRelease(url);
			}
			CFRelease((__bridge CFTypeRef)(array));
		}
		else
			asl_NSLog(ASL_LEVEL_WARNING, @"Warning: _IsLoginItem : LSSharedFileListCopySnapshot delivered NULL list!");

		CFRelease(list);
	}
	else
		asl_NSLog(ASL_LEVEL_WARNING, @"Warning: _IsLoginItem : LSSharedFileListCreate delivered NULL list!");

	return tmp;
}
@end
