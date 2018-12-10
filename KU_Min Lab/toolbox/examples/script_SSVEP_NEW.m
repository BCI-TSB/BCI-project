%% script_SSVEP_NEW ver 0.60
%
%% [*Examples]--------------------------------------------------
%	script_SSVEP_NEW.m �� ��� �ʿ��� parameter���� ������ ��, �Ʒ� ����
%	[���ǻ���] MATLAB 2016a ���� ������� �����ؾ� �� (bbci �� �����Լ� �̽�)
%
%	MATLAB> help script_SSVEP_NEW
%	MATLAB> script_SSVEP_NEW
%	(���� ����� �Ʒ����� ����ϴ� hEEG.Dst �� ������ ���� �Ʒ��� �����)
%
% License
% ==============================================================
% This program is minlab toolbox.
%
% Copyright (C) 2015 MinLAB. of the University of Korea. All rights reserved.
% Correspondence: tigoum@korea.ac.kr
% Web: mindbrain.korea.ac.kr
%
% ==============================================================================
% Revision Logs
% ------------------------------------------------------
% Program Editor: Ahn Min-Hee @ tigoum, University of Korean, KOREA
% User feedback welcome: e-mail::tigoum@korea.ac.kr
% ......................................................
% first created at 2016/03/23
% last  updated at 2018/03/29
% ......................................................
% ver 0.10 : 20160325. H_class.m �Լ� ���� ����
% ver 0.20 : 20160722. SSVEP ����, ���� ���ļ� ������ -> ��������
% ver 0.30 : 20170817. sub�Լ��� ����ó�� ����ȭ �� �ӵ� ������ �����ϴ� test
% ver 0.40 : 20170925. ���ļ� �������� accuracy ���� ���ɼ� ����
% ver 0.50 : 20171119. hEEG ���� ����, bbci�� ���� ������
% ver 0.60 : 20180327. ����: OSS�� ���� toolbox ����ȭ
% ==============================================================================
%
% first created by tigoum 2015/11/18
% last  updated by tigoum 2018/03/30

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% MATLAB release ����, bbci ���� <- MATLAB2016b ���� ��������
Version				=	ver;
Release				=	Version.Release;					% ����: R(2016a)
nRel				=	str2num(Release(3:6));
Half				=	Release(7);
if 2016 < nRel | (2016==nRel & 'b' <= Half)
 error('MATLAB version too big, because bbci is issued on MATLAB2016b later');
end

%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%	Top Down SSVEP�� ����:
%
%	�⺻ ������ �� '��' ���� ���ο� ���ο� ���� �ٸ� ���ļ��� �Ҵ��ϰ� ������
%		������
%		������
%		������
%	�� �׸��� ���� �Ʒ��� ���� ���ļ��� �����.
%
%%		5.5	6.5 7.5
%%		|	|	|
%%	5.0- ��  ��  ��	R1
%%	6.0- ��  ��  ��	R2
%%	7.0- ��  ��  ��	R3
%%		C1	C2	C3
%
%	�̸� �������� �Ʒ��� ���� �����Ǵ� ���ں��� ���ļ� ����(harmonic)�� ������
%	tgr	R/C		char	R-freq	C-freq
%	1x1	R1C3	(��)	5.0 Hz	7.5 Hz
%	1x2	R3C1	(��)	7.0 Hz	5.5 Hz
%	1x3	R2C1	(��)	6.0 Hz	5.5 Hz
%	1x4	R2C3	(��)	6.0 Hz	7.5 Hz
%	1x5	R3C2	(��)	7.0 Hz	6.5 Hz
%	1x6	R1C2	(��)	5.0 Hz	6.5 Hz
%	->	tgr 1x. ���� x == 1(top down), 2(intermediate), 3(bottom up)

% ---------------------------------------------------------------------------
% ������ ���� ȯ�漳��
% ---------------------------------------------------------------------------
%% �⺻������ m file�� path�����̹Ƿ�, MATLAB�󿡼� ��μ��� ���൵ ��.
%addpath( genpath( fullfile( '/usr/local', 'bbci_public' ) ), '-end');	% �ǹ�
%addpath( genpath( fullfile( '../', 'bbci_public-master' ) ) );

addpath( genpath( fullfile( '../', 'fileio' ) ) );
addpath( genpath( fullfile( '../', 'SpectralDensity_Discriminability' ) ) );
addpath( genpath( fullfile( '../', 'examples' ) ) );

% ---------------------------------------------------------------------------
% �����͸� �ε��ϱ� ���� path �� file ���� ����
% ---------------------------------------------------------------------------
	%% initialize variables
	hEEG.Condi		=	{ 'TopDown', }; %'Intermediate', 'BottomUp', };
	%----------------------------------------------------------------------------
	hEEG.PATH		=	'../'
	hEEG.Src		=	'samples';
	hEEG.Dst		=	fullfile('.', 'Results');			% examples/Results

	hEEG.Head		=	'SSVEP_NEW';
	hEEG.Inlier		=	{	'su0003', 'su0004', 'su0005',	};

% ---------------------------------------------------------------------------
% �����͸� ����ϱ� ���� �ʱⰪ ����
% ---------------------------------------------------------------------------
	hEEG.SmplRate	=	500;								% sampling rate
	fBin			=	1/2;
	hEEG.FreqBins	=	fBin;								% freq step

	%----------------------------------------------------------------------------
	% FOI == band of interest
	hEEG.FOI		=	{ [5:fBin:13.5] };					% �ٽ� ���� ���ļ�
	% ������ �� FOI�� ���� ���� (�׷����� �ּ����� ����ϱ� ���� �뵵)
	hEEG.sFOI		=	{ 'over stimulation frequencies', };% ���� FOI ����
%%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	hEEG.FreqWindow	=	[min(cell2mat(hEEG.FOI)), max(cell2mat(hEEG.FOI))];

	%----------------------------------------------------------------------------
%	hEEG.tInterval	=	[-2000, 5000];						% -2000~5000msec
	hEEG.tInterval	=	[0, 5000];							% 0 ~ 5000msec
	hEEG.TimeWindow	=	[0, 5000];							% 0 ~ 5000msec

	%----------------------------------------------------------------------------
	hEEG.nFolds		=	4;									% 4 session
	hEEG.Chan		=	{		...	% ���⿡ ����ϴ� ä�ο� ���ؼ� plotting ��.
				'Fp1',	'Fp2',	'F7',	'F3',	'Fz',	'F4',	'F8',	'FC5',...
				'FC1',	'FC2',	'FC6',	'T7',	'C3',	'Cz',	'C4',	'T8', ...
						'CP5',	'CP1',	'CP2',	'CP6',			'P7',	'P3', ...
				'Pz',	'P4',	'P8',	'PO9',	'O1',	'Oz',	'O2',	'PO10' };
				 % ���� �� 30ä�� ���, {'O1','Oz','O2'} ��� -> 3���� plot
%	hEEG.ChRemv		=	{	'not',	'NULL*', '*EOG*'	};	%����: �տ�'not'�߰�
	hEEG.nChannel	=	length(hEEG.Chan);					% ���� ��� �� ä��

%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
for condi			=	1 : length(hEEG.Condi)
	hEEG.CurCond	=	hEEG.Condi{condi};

	% ___________________________________________________________________________
	epos			=	cell(1,length(hEEG.Inlier));		% data ����
	for ix 	= 1:length(hEEG.Inlier)	% ����ӵ��� �����ϰ� ������, parfor ����
		fprintf('loading subject %s\n', hEEG.Inlier{ix})

		epos{ix}	=	eEEG2epo( hEEG, ix );

		if isfield(hEEG, 'Chan')
			epos{ix}=	proc_selectChannels(epos{ix}, hEEG.Chan);	% ���ù��
		else
			epos{ix}=	proc_selectChannels(epos{ix}, hEEG.ChRemv);	% ���Ź��
		end
	end
	hEEG.nChannel	=	length(epos{1}.clab);				% ����

	%% drawing for spectral-density & discriminability -------------------
	Cnt				=	viz_spectra_discri( hEEG, epos );
end		% for cond

