(******************************************************************************

______________________________________________________________________________

YouTube Downloader                                        (C) 2009, 2010 Pepak
http://www.pepak.net/download/youtube-downloader/         http://www.pepak.net
______________________________________________________________________________


Copyright (c) 2010, Pepak (http://www.pepak.net)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Pepak nor the
      names of his contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL PEPAK BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************)

unit guiConsts;
{$INCLUDE 'ytd.inc'}

interface

uses
  uDownloadThread;
  
{gnugettext: scan-all}
const
  THREADSTATE_WAITING = 'Waiting'; // GUI: Download thread state: Waiting for its turn
  THREADSTATE_PREPARING = 'Preparing'; // GUI: Download thread state: Preparing download (getting title, URL...)
  THREADSTATE_DOWNLOADING = 'Downloading'; // GUI: Download thread state: Downloading
  THREADSTATE_FINISHED = 'Finished'; // GUI: Download thread state: Download finished successfully
  THREADSTATE_FAILED = 'Failed'; // GUI: Download thread state: Download failed
  THREADSTATE_ABORTED = 'Aborted'; // GUI: Download thread state: Download was aborted by user

{$IFDEF CONVERTERS}
const
  CONVERTTHREADSTATE_WAITING = 'Awaiting conversion'; // GUI: Convert thread state: Waiting for its turn
  CONVERTTHREADSTATE_CONVERTING = 'Converting'; // GUI: Convert thread state: Converting
  CONVERTTHREADSTATE_FINISHED = 'Converted'; // GUI: Convert thread state: Conversion finishes successfully
  CONVERTTHREADSTATE_FAILED = 'Conversion failed'; // GUI: Convert thread state: Conversion failed
  CONVERTTHREADSTATE_FAILEDRUN = 'Converter not found'; // GUI: Convert thread state: Failed to start the converter

const
  CONVERTERS_NOCONVERTER = '** None **'; // GUI: description of a "no converter"

{$IFDEF CONVERTERSMUSTBEACTIVATED}
const
  CONVERTERS_INACTIVE_WARNING = 'Converters are not activated.'#10#10 +
    'You must activate them through manually editing'#10 +
    'the configuration file. You can find the steps'#10 +
    'needed in the documenation.'#10#10 +
    'The reason why this is necessary is, converters'#10 +
    'NEED to be configured properly, as documented,'#10 +
    'but too many people failed to read the documentation'#10 +
    'and instead complained that converters don''t work.';
{$ENDIF}
{$ENDIF}

{gnugettext: reset}

const
  ThreadStates: array[TDownloadThreadState] of string
              = (THREADSTATE_WAITING, THREADSTATE_PREPARING, THREADSTATE_DOWNLOADING, THREADSTATE_FINISHED, THREADSTATE_FAILED, THREADSTATE_ABORTED);

{$IFDEF CONVERTERS}
const
  ConvertThreadStates: array[TConvertThreadState] of string
              = (CONVERTTHREADSTATE_WAITING, CONVERTTHREADSTATE_CONVERTING, CONVERTTHREADSTATE_FINISHED, CONVERTTHREADSTATE_FAILED, CONVERTTHREADSTATE_FAILEDRUN);
{$ENDIF}

implementation

end.