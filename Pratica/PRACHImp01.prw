#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} PRACHI01

Importacao de Naturezas

@author Thierry Pereira 
@since 13/02/2023

/*/

User Function PRACHIMP01()

    Local aRet			:= {}
	Local aArea         := GetArea()

	SaveInter()

    If ParamBox({	{6,"Selecione Arquivo",PadR("",150),"",,"", 90 ,.T.,"Importacao Naturezas","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE}},;
            "Importacao Naturezas Pratica Chile",@aRet)

        MsgRun("Lendo produtos arquivo csv...", "Titulo", {|| PraPrdImp01( lEnd, aRet[1] ) })

    EndIf

    RestInter()

	RestArea(aArea)

Return

//--------------------------------------------------
	/*/{Protheus.doc} PraNatImp01
	Importa registros e grava naturezas 
	
    @author Thierry Pereira
    @since 13/02/2023
	 
	@return 
	/*/
//--------------------------------------------------

Static Function PranatImp01(lEnd, cArq)
	
	Local aArea       := GetArea()
	Local aCampos     := {}
	Local aDados      := {}
    //Local aAuto       := {}
	Local lPrim       := .T.
	Local cLinha      := ""
	Local nTotal      := 0
	Local nTot2       := 0
	Local nNumCob     := 0
	Local nx          := 0
    Local lRet        := .T.
    Local nLoop       := 0
    Local cMsgErro    := ''
    Local aErrPCAuto  := {}
    //Local aAI0Auto    := {}
    Local aProd       := {}
    Local lRetorno    := .F.
    Local nConta      := 0
	
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

    For nx := 1 To Len(aDados)

        ConfirmSx8("SED", "SED_COD")

        aProd :=       {{'SED_FILIAL'    ,xFilial("SB1")                                                                        ,Nil},;
                        {'SED_COD'       ,Alltrim(aDados[nx][1])                                                                ,Nil},;
                        {'SED_DESC'      ,Alltrim(aDados[nx][2])                                                                ,Nil},;
                        {'SED_MODELO'    ,Alltrim(aDados[nx][3])                                                                ,Nil},;
                        {'SED_TIPO'      ,Alltrim(aDados[nx][4])                                                                ,Nil},;
                        {'SED_UM'        ,Alltrim(aDados[nx][5])                                                                ,Nil},;
                        {'SED_POSIPI'    ,IIF(Empty(Alltrim(aDados[nx][6])), "" ,Alltrim(strtran(aDados[nx][6],'N/A','')))      ,Nil},;
                        {'SED_CONV'      ,Val(strtran(aDados[nx][8],"N/A","0"))                                                 ,Nil},;
                        {'SED_CODBAR'    ,Alltrim(strtran(aDados[nx][9],'N/A',""))                                              ,Nil},;
                        {'SED_CODGTIN'   ,Alltrim(strtran(aDados[nx][10],'N/A',""))                                             ,Nil},;
                        {'SED_ORIGEM'    ,Alltrim(strtran(aDados[nx][11],"N/A",""))                                             ,Nil},;
                        {'SED_RASTRO'    ,IIF(Empty(Alltrim(aDados[nx][12])), "N" ,Alltrim(strtran(aDados[nx][12],'N/A','N')))  ,Nil},;
                        {'SED_CODISS'    ,Alltrim(strtran(aDados[nx][13],'N/A',''))                                             ,Nil},;
                        {'SED_LOCALIZ'   ,IIF(Empty(Alltrim(aDados[nx][14])), "N" ,Alltrim(strtran(aDados[nx][14],'N/A','N')))  ,Nil},;
                        {'B1_CONTA'      ,Alltrim(strtran(aDados[nx][17],'.',''))                                            ,Nil},;
                        {'SED_LOCPAD'    ,IIF(Empty(Alltrim(aDados[nx][16])), "1" ,Alltrim(aDados[nx][16]))                     ,Nil}}
                        
                        
                        //{'B1_CC'        ,Alltrim(aDados[nx][18])                                                     ,Nil}}

        MSExecAuto({|x,y| Fina010(x,y)},aProd,3)
            
        If lMsErroAuto  

            lRet := lMsErroAuto

            If lMsErroAuto
                DisarmTransaction()
            EndIf

            Conout("Natureza não cadastrada!")

            aErrPCAuto	:= GETAUTOGRLOG()
            cMsgErro	:= ""

            For nLoop := 1 To Len(aErrPCAuto)
                cMsgErro += EncodeUTF8(StrTran(Alltrim(aErrPCAuto[nLoop]),CRLF,''))
            Next
            Conout(cMsgErro)

           FWAlertError(cMsgErro, "Erro")
            
        Else

            nConta ++

            ConfirmSx8()

            Conout("Natureza incluida com sucesso!")
            
        EndIf

        aProd := {}

        lMsErroAuto := .F.

    Next

	RestArea(aArea)

    FWAlertSuccess("Total de Naturezas inclusas: " + cValTochar(nConta) , "Natureza")

Return lRetorno

