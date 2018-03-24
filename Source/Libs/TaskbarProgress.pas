{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
unit TaskbarProgress;

interface

uses
  Windows;

{$MINENUMSIZE 4}

type
  ULONGLONG = UInt64;

  HIMAGELIST = THandle;

  THUMBBUTTONMASK = (
    THB_BITMAP  = $00000001,
    THB_ICON    = $00000002,
    THB_TOOLTIP = $00000004,
    THB_FLAGS   = $00000008
  );

  THUMBBUTTONFLAGS = (
    THBF_ENABLED        = $00000000,
    THBF_DISABLED       = $00000001,
    THBF_DISMISSONCLICK = $00000002,
    THBF_NOBACKGROUND   = $00000004,
    THBF_HIDDEN         = $00000008,
    THBF_NONINTERACTIVE = $00000010
  );

  THUMBBUTTON = record
    dwMask:   THUMBBUTTONMASK;
    iId:      UINT;
    iBitmap:  UINT;
    hIcon:    HICON;
    szTip:    array[0..259] of WideChar;
    dwFlags:  THUMBBUTTONFLAGS;
  end;
  PTHUMBBUTTON = ^THUMBBUTTON;
  LPTHUMBBUTTON = PTHUMBBUTTON;

  TBPFLAG = (
    TBPF_NOPROGRESS    = $00000000,
    TBPF_INDETERMINATE = $00000001,
    TBPF_NORMAL        = $00000002,
    TBPF_ERROR         = $00000004,
    TBPF_PAUSED        = $00000008
  );

  STPFLAG = (
    STPF_NONE                      = $00000000,
    STPF_USEAPPTHUMBNAILALWAYS     = $00000001,
    STPF_USEAPPTHUMBNAILWHENACTIVE = $00000002,
    STPF_USEAPPPEEKALWAYS          = $00000004,
    STPF_USEAPPPEEKWHENACTIVE      = $00000008
  );

const
  IID_ITaskbarList: TGUID = '{56FDF342-FD6D-11d0-958A-006097C9A090}';

type
  ITaskbarList = interface(IUnknown)
  ['{56FDF342-FD6D-11d0-958A-006097C9A090}']
    Function HrInit: HRESULT; stdcall;
    Function AddTab(hwnd: HWND): HRESULT; stdcall;
    Function DeleteTab(hwnd: HWND): HRESULT; stdcall;
    Function ActivateTab(hwnd: HWND): HRESULT; stdcall;
    Function SetActiveAlt(hwnd: HWND): HRESULT; stdcall;
  end;

const
  IID_ITaskbarList2: TGUID = '{602D4995-B13A-429b-A66E-1935E44F4317}';

type
  ITaskbarList2 = interface(ITaskbarList)
  ['{602D4995-B13A-429b-A66E-1935E44F4317}']
    Function MarkFullscreenWindow(hwnd: HWND; fFullscreen: BOOL): HRESULT; stdcall;
  end;

const
  IID_ITaskbarList3: TGUID = '{ea1afb91-9e28-4b86-90e9-9e9f8a5eefaf}';

type
  ITaskbarList3 = interface(ITaskbarList2)
  ['{ea1afb91-9e28-4b86-90e9-9e9f8a5eefaf}']
    Function SetProgressValue(hwnd: HWND; ullCompleted: ULONGLONG; ullTotal: ULONGLONG): HRESULT; stdcall;
    Function SetProgressState(hwnd: HWND; tbpFlags: TBPFLAG): HRESULT; stdcall;
    Function RegisterTab(hwndTab: HWND; hwndMDI: HWND): HRESULT; stdcall;
    Function UnregisterTab(hwndTab: HWND): HRESULT; stdcall;
    Function SetTabOrder(hwndTab: HWND; hwndInsertBefore: HWND): HRESULT; stdcall;
    Function SetTabActive(hwndTab: HWND; hwndMDI: HWND; dwReserved: DWORD): HRESULT; stdcall;
    Function ThumbBarAddButtons(hwnd: HWND; cButtons: UINT; pButton: LPTHUMBBUTTON): HRESULT; stdcall;
    Function ThumbBarUpdateButtons(hwnd: HWND; cButtons: UINT; pButton: LPTHUMBBUTTON): HRESULT; stdcall;
    Function ThumbBarSetImageList(hwnd: HWND; himl: HIMAGELIST): HRESULT; stdcall;
    Function SetOverlayIcon(hwnd: HWND; hicon: HICON; pszDescription: LPCWSTR): HRESULT; stdcall;
    Function SetThumbnailTooltip(hwnd: HWND; pszTip: LPCWSTR): HRESULT; stdcall;
    Function SetThumbnailClip(hwnd: HWND; prcClip: PRECT): HRESULT; stdcall;
  end;

const
  IID_ITaskbarList4: TGUID = '{c43dc798-95d1-4bea-9030-bb99e2983a1a}';

type
  ITaskbarList4 = interface(ITaskbarList3)
  ['{c43dc798-95d1-4bea-9030-bb99e2983a1a}']
    Function SetTabProperties(hwndTab: HWND; stpFlags: STPFLAG): HRESULT; stdcall;
  end;

const
  CLSID_TaskbarList: TGUID = '{56FDF344-FD6D-11d0-958A-006097C9A090}';

//==============================================================================

type
  TTaskbarProgressState = (tpsNoProgress, tpsIndeterminate, tpsNormal, tpsError, tpsPaused);

Function TaskbarProgressActive: Boolean;

Function SetTaskbarProgressState(State: TTaskbarProgressState): Boolean;
Function SetTaskbarProgressValue(Value: Single): Boolean;

implementation

uses
  ActiveX,{$IFDEF FPC} InterfaceBase {$ELSE} Forms{$ENDIF};

var
  TaskbarList: ITaskbarList4 = nil;

//------------------------------------------------------------------------------

Function TaskbarProgressActive: Boolean;
begin
Result := Assigned(TaskbarList);
end;
//------------------------------------------------------------------------------

Function SetTaskbarProgressState(State: TTaskbarProgressState): Boolean;
var
  ProgressState:  TBPFLAG;
begin
If TaskbarProgressActive then
  begin
    case State of
      tpsIndeterminate: ProgressState := TBPF_INDETERMINATE;
      tpsNormal:        ProgressState := TBPF_NORMAL;
      tpsError:         ProgressState := TBPF_ERROR;
      tpsPaused:        ProgressState := TBPF_PAUSED;
    else
     {tpsNoProgress}
      ProgressState := TBPF_NOPROGRESS;
    end;
  {$IFDEF FPC}
    Result := Succeeded(TaskbarList.SetProgressState(WidgetSet.AppHandle,ProgressState));
  {$ELSE}
    Result := Succeeded(TaskbarList.SetProgressState(Application.Handle,ProgressState));
  {$ENDIF}
  end
else Result := False;
end;

//------------------------------------------------------------------------------

Function SetTaskbarProgressValue(Value: Single): Boolean;
begin
If TaskbarProgressActive then
{$IFDEF FPC}
  Result := Succeeded(TaskbarList.SetProgressValue(WidgetSet.AppHandle,Trunc(Value * 1000),1000))
{$ELSE}
  Result := Succeeded(TaskbarList.SetProgressValue(Application.Handle,Trunc(Value * 1000),1000))
{$ENDIF}
else
  Result := False;
end;

//==============================================================================

procedure Initialize;
begin
If Succeeded(CoInitialize(nil)) then
  begin
    If Succeeded(CoCreateInstance(CLSID_TaskbarList,nil,CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER,IID_ITaskbarList4,TaskbarList)) then
      begin
        If TaskbarList.HrInit <> S_OK then
          begin
            TaskbarList := nil; // TaskbarList.Relase
            CoUninitialize;
          end;
      end
    else CoUninitialize;
  end;
end;

//------------------------------------------------------------------------------

procedure Finalize;
begin
If Assigned(TaskbarList) then
  begin
    TaskbarList := nil; // TaskbarList.Relase
    CoUninitialize;
  end;
end;

//------------------------------------------------------------------------------

initialization
  Initialize;

finalization
  finalize;

end.
