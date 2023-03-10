#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} NEWIMP03

importacao de Contas a Pagar    
@author Brito
@since 28/12/2022

/*/

User Function NEWIMP03()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"importacao Titulos a Pagar","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "importacao Titulos a Pagar New Aco",@aRet)

        Processa({|| NewPagImp03( lEnd, aRet[1] )}, "Lendo titulos arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} NewPagImp03
	Importa registros e grava titulos a pagar
	
    @author Brito
    @since 22/11/2022
	 
	@return 
	/*/
//--------------------------------------------------

Static Function NewPagImp03(lEnd, cArq)
	
	Local aArea       := GetArea()
	Local aCampos     := {}
	Local aDados      := {}
    Local aAuto       := {}
	Local lPrim       := .T.
	Local cLinha      := ""
	Local nTotal      := 0
	Local nTot2       := 0
	Local nNumCob     := 0
	Local nx          := 0
    Local lRet        := .T.
    Local aAI0Auto    := {}
    Local lRetorno    := .F.
    Local nConta      := 0
    Local nAtual      := 0
    Local nLoop       := 0
    Local cNum        := ""
	
    Private lMsErroAuto     as logical
	Private lMsHelpAuto	    as logical
	Private lAutoErrNoFile  as logical
	Private aErro     := {}
	Private HrIn      := Time()    
	Private HrFin
	Private aErros    := {}

    lMsErroAuto 	:= .F.
	lMsHelpAuto		:= .T.
	lAutoErrNoFile	:= .T.

 
	If !File(cArq)
		MsgStop("O arquivo "  + cArq + " nao foi encontrado. A importacao sera abortada!","ATENCAO")
		Return
	EndIf
 
	FT_FUSE(cArq)
	FT_FGOTOP()

	nTot2 := FT_FLASTREC()

	While !FT_FEOF()

		nNumCob := nNumCob + 1

		cLinha := FT_FREADLN()
 
		If lPrim
			aCampos := Separa(cLinha,";",.T.)
			lPrim := .F.
		Else
			AADD(aDados,Separa(cLinha,";",.T.))
		EndIf
 
		FT_FSKIP()
	EndDo

	nTotal := Len(aDados)

    ProcRegua(nTotal)

    For nx := 1 To Len(aDados)

        nAtual++

        cNum := GetSXENum( "SE2", "E2_NUM" ) 

        ConfirmSx8("SE2", "E2_NUM")

        IncProc("Analisando titulo a pagar " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

        aAdd(aAuto, {"E2_FILIAL"   , FWxFilial("SE2")                                                                           ,Nil})
        aAdd(aAuto, {"E2_NUM"      , cNum                                                                                       ,Nil})
        aAdd(aAuto, {"E2_TIPO"     , 'NF'                                                                                       ,Nil})
        aAdd(aAuto, {"E2_NATUREZ"  , '1010101'                                                                                  ,Nil})
        aAdd(aAuto, {"E2_FORNECE"  , Imp03For(aDados[nx][7])                                                                    ,Nil})
        aAdd(aAuto, {"E2_LOJA"     , '01'                                                                                       ,Nil})
        aAdd(aAuto, {"E2_EMISSAO"  , Stod(SubStr(aDados[nx][8],1,4)+ SubStr(aDados[nx][8],6,2)  + SubStr(aDados[nx][8],9,2))    ,Nil})
        aAdd(aAuto, {"E2_VENCTO"   , Stod(SubStr(aDados[nx][3],1,4) + SubStr(aDados[nx][3],6,2)  + SubStr(aDados[nx][3],9,2))   ,Nil})
        aAdd(aAuto, {"E2_VENCREA"  , Stod(SubStr(aDados[nx][3],1,4) + SubStr(aDados[nx][3],6,2)  + SubStr(aDados[nx][3],9,2))   ,Nil})
        aAdd(aAuto, {"E2_VALOR"    , Val(aDados[nx][4])                                                                         ,Nil})
        aAdd(aAuto, {"E2_SALDO"    , Val(aDados[nx][4]) - Val(aDados[nx][10])                                                   ,Nil})
        aAdd(aAuto, {"E2_JUROS"    , Val(aDados[nx][11])                                                                        ,Nil})
        aAdd(aAuto, {"E2_DESCONT"  , Val(aDados[nx][9])                                                                         ,Nil})
        aAdd(aAuto, {"E2_HIST"     , Alltrim(DecodeUTF8(aDados[nx][12]))                                                        ,Nil})
        aAdd(aAuto, {"E2_MOEDA"    , 1                                                                                          ,Nil})
        aAdd(aAuto, {"E2_ZZCDLEG"  , U_convStr(U_NEWGENASP(aDados[nx][1]))                                                 ,Nil})

        MSExecAuto({|x,y| FINA050(x,y)}, aAuto, 3)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Titulo nao cadastrado!")

            aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")

            
        Else

            Conout("Titulo incluso com sucesso!")

            nConta ++
            
        EndIf

        aAuto := {}
        
        lMsErroAuto := .F.
    Next

	RestArea(aArea)

     FWAlertSuccess("Total de titulos inclusos: " + cValTochar(nConta) , "Titulos a Pagar")

Return lRetorno


//--------------------------------------------------
	/*/{Protheus.doc} Imp03For
	Retorna codigo do fornecedor atual, a partir do codigo legado
	
    @author Brito
    @since 02/01/2023
	 
	@return 
	/*/
//--------------------------------------------------

Static Function Imp03For(cCodLeg)

    Local aArea       := GetArea()
    Local cFornecedor := ""

    cCodLeg := Alltrim(U_NEWGENASP(cCodLeg))

    DbSelectArea("SA2")
    DbSetOrder(11)

    If DbSeek(xFilial("SA2") + cCodLeg)
        cFornecedor := SA2->A2_COD
    EndIf 

    RestArea(aArea)

Return cFornecedor
