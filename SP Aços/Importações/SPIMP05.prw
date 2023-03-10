#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} NEWIMP05

Importação de Contas a Receber
@author Thierry Pereira 
@since 13/01/2023

/*/

User Function SPIMP05()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importação Títulos a Receber","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importação Títulos a Receber SP Acos",@aRet)

        Processa({|| NewRecImp05( lEnd, aRet[1] )}, "Lendo títulos arquivo csv...")

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} NewRecImp05
	Importa registros e grava títulos a receber
	
   @author Thierry Pereira
   @since 13/01/2023
	 
	@return 
	/*/
//--------------------------------------------------

Static Function NewRecImp05(lEnd, cArq)
	
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
    //Local aAI0Auto    := {}
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
		MsgStop("O arquivo "  + cArq + " não foi encontrado. A importação será abortada!","ATENCAO")
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

        cNum := GetSXENum( "SE1", "E1_NUM" ) 

        ConfirmSx8("SE1", "E1_NUM")

        IncProc("Analisando título a receber " + cValToChar(nAtual) + " de " + cValToChar(nTotal) + "...")

        If Len(aDados[nx]) >= 12
            aAdd(aAuto, {"E1_FILIAL"   ,FWxFilial("SE2")                                                                                ,Nil})
            aAdd(aAuto, {"E1_NUM"      ,cNum                                                                                            ,Nil})
            aAdd(aAuto, {"E1_TIPO"     ,'NF'                                                                                            ,Nil})
            aAdd(aAuto, {"E1_NATUREZ"  ,'1010101'                                                                                       ,Nil})
            aAdd(aAuto, {"E1_CLIENTE"  ,Imp05Cli(aDados[nx][3])                                                                         ,Nil})
            aAdd(aAuto, {"E1_LOJA"     ,'01'                                                                                            ,Nil})
            aAdd(aAuto, {"E1_EMISSAO"  ,Stod(SubStr(aDados[nx][9],7,4)  + SubStr(aDados[nx][9],4,2)  + SubStr(aDados[nx][6],1,2))       ,Nil})
            aAdd(aAuto, {"E1_VENCTO"   ,Stod(SubStr(aDados[nx][10],7,4) + SubStr(aDados[nx][10],4,2) + SubStr(aDados[nx][10],1,2))      ,Nil})
            aAdd(aAuto, {"E1_VENCREA"  ,Stod(SubStr(aDados[nx][10],7,4) + SubStr(aDados[nx][10],4,2) + SubStr(aDados[nx][10],1,2))      ,Nil})
            aAdd(aAuto, {"E1_VALOR"    ,Val(aDados[nx][19])                                                                             ,Nil})
            aAdd(aAuto, {"E1_SALDO"    ,Val(aDados[nx][19]) - Val(aDados[nx][20])                                                       ,Nil})
            aAdd(aAuto, {"E1_JUROS"    ,Val(aDados[nx][16])                                                                             ,Nil})
            aAdd(aAuto, {"E1_DESCONT"  ,Val(aDados[nx][11])                                                                             ,Nil})
            aAdd(aAuto, {"E1_PEDIDO"   ,Alltrim(U_NEWGENASP(aDados[nx][7]))                                                             ,Nil})
            aAdd(aAuto, {"E1_BAIXA"    ,Stod(SubStr(aDados[nx][27],7,4) + SubStr(aDados[nx][27],4,2)  + SubStr(aDados[nx][27],1,2))     ,Nil})
            aAdd(aAuto, {"E1_HIST"     ,Alltrim(DecodeUTF8(aDados[nx][12]))                                                             ,Nil})
            aAdd(aAuto, {"E1_MOEDA"    ,1                                                                                               ,Nil})
            aAdd(aAuto, {"E1_ZZCDLEG"  ,U_convStr(U_NEWGENASP(aDados[nx][1]))                                                           ,Nil})
                  
            MSExecAuto({|x,y| FINA040(x,y)}, aAuto, 3)
                
            If lMsErroAuto  

                lRet := lMsErroAuto

                If lMsErroAuto
                    DisarmTransaction()
                EndIf

                Conout("Título não cadastrado!")

                aErrPCAuto	:= GETAUTOGRLOG()
                cMsgErro	:= ""

                For nLoop := 1 To Len(aErrPCAuto)
                    cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
                Next
                Conout(cMsgErro)

            FWAlertError(cMsgErro, "Erro")

                
            Else

                Conout("Título incluso com sucesso!")

                nConta ++
                
            EndIf

            aAuto := {}
            
            lMsErroAuto := .F.
        EndIf
    Next

	RestArea(aArea)

     FWAlertSuccess("Total de títulos inclusos: " + cValTochar(nConta) , "Títulos a Receber")

Return lRetorno

//--------------------------------------------------
	/*/{Protheus.doc} Imp05Cli
	Retorna código do cliente atual, a partir do codigo legado
	
    @author Brito
    @since 02/01/2023
	 
	@return 
	/*/
//--------------------------------------------------

Static Function Imp05Cli(cCodLeg)

    Local aArea       := GetArea()
    Local cCliente    := ""

    cCodLeg := Alltrim(U_NEWGENASP(cCodLeg))

    DbSelectArea("SA1")
    DbSetOrder(14)

    If DbSeek(xFilial("SA1") + cCodLeg)
        cCliente := SA1->A1_COD
    EndIf 

    RestArea(aArea)

Return cCliente
    