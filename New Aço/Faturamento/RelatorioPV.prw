#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"
#INCLUDE "FONT.CH"
#INCLUDE "TOPCONN.CH"

#DEFINE TAM_NUMEROS 		30

//TODO atualizar todos protheus doc
//TODO definir pontos de entrada
//TODO flexibilizar calculos
//TODO finalizar envio de email - pendente da correcao do niemeyer
//TODO avaliar erro - nao grava pdf caso o path nao seja no servidor ou o nome do arquivo nao seja o padrao
//TODO criar layout dinamico em HTML que seja parametrizado
//TODO incluir impostos no relatorio mas que sua exibicao seja condicional de acordo com parametros
//TODO implementar logo email AllTrim(GETMV("ZZ_LOGOEXT"))
/*/{Protheus.doc} RelPV

Função principal para início da geração do relatório de pedido de venda

@type function 
@author Eduardo Silli Rufim
@since 27/06/2016
@version 2.00

@history 22/07/2016, Carlos Eduardo Niemeyer Rodrigues, Inclusão do IPLicense e Ajsutes ProtheusDoc
 
@param [cFileName], String, Nome do arquivo .Pdf que será gerado
@param [cTitle], String, Título que será exibido na parte superior
@param [cFont], String, Nome da fonte que será utilizada como padrão
@param [nFontSize], Inteiro, Tamanho da fonte que será utilizado como padrão
@param [lAsk], Lógico, Define se será exibida a tela de configuração do relatório
@param [lShowReport], Lógico, Define se o PDF será aberto automaticamente após a geração
/*/
User Function RelPV(cNumPedido, cFileName, cTitle, cFont, nFontSize, lAsk, lShowReport, lIsHtml)
	Local lLicensed	:= .F.
	Local oRelPV 	:= Nil
	
	Begin Sequence
		oRelPV 		:= RelPV():newRelPV(cNumPedido, cFileName, cTitle, cFont, nFontSize, lAsk, lShowReport, lIsHtml)
		lLicensed	:= .T.
	End Sequence	
	
	If !( lLicensed )
		Return
	Endif
	 
	if(oRelPV:lAsk .AND. !oRelPV:lIsAuto)
		if !oRelPV:ask(cNumPedido)
			return
		endif
	endif
	
	If(!oRelPV:lIsHtml)
		If MsgYesNo("Deseja Enviar Relatório em HTML por E-Mail?","Envia HTML via E-Mail")
			oRelPV:lIsHtml := .T.
		endif
	endif
	
	oRelPV:preview()
Return

/*
@property cFileName, String, Nome do arquivo .Pdf que será gerado
@property cTitle, String, Título que será exibido na parte superior
@property oFont, TFont, 
@property nFontSize, Inteiro, Tamanho da fonte que será utilizado como padrão
@property lAsk, Lógico, Define se será exibida a tela de configuração do relatório
@property oPdf, IpPdfObject,
@property cNumPedido, String, 
@property lIsAuto, Lógico, 
@property cQuery, String, 
@property oSql, IpSqlObject,
*/
//TODO avaliar o formato do protheusdoc para atributos

/*/{Protheus.doc} RelPV

Classe responsável pelas definições do relatório de pedido de venda

@type class  
@author Eduardo Silli Rufim
@since 27/06/2016
/*/
Class RelPV
	Data cTitle
	Data cFileName
	Data oPdf
	Data cNumPedido
	Data oFont
	Data lIsAuto                                                                                                                                 
	Data cQuery
	Data oSql
	Data lAsk
	Data cHtml
	Data lIsHtml

	Method newRelPV(cNumPedido, cFileName, cTitle, cFont, nFontSize, lAsk, lShowReport) Constructor	
	Method preview()
	Method ask(cNumPedido)	
	Method addField(cSelect)
	Method addFrom(cFrom)
	Method addWhere(cWhere)
	Method addOrderBy(cOrder)
	
	//Gets e Sets
	Method getTitle()
	Method setTitle(cTitle)
	
	Method getFileName()
	Method setFileName(cFileName)
	
	Method getFont()
	Method setFont(oFont)
	
	Method getAsk()
	Method setAsk(lAsk)	
	
	Method getQuery()
	Method setQuery(cQuery)
	
	Method getHtml()
	Method setHtml(cHtml)
	
	Method getNumPedido()
	Method setNumPedido(cNumPedido)
	
	Method isHtml()
	Method setIsHtml(lIsHtml)	
	
	Method getValue(cField)

EndClass

/*/{Protheus.doc} newRelPV

Método construtor

@type method 
@author Eduardo Silli Rufim
@since 27/06/2016
 
@param [cFileName], String, Nome do arquivo .Pdf que será gerado
@param [cTitle], String, Título que será exibido na parte superior
@param [cFont], String, Nome da fonte que será utilizada como padrão
@param [nFontSize], Inteiro, Tamanho da fonte que será utilizado como padrão
@param [lAsk], Lógico, Define se será exibida a tela de configuração do relatório
@param [lShowReport], Lógico, Define se o PDF será aberto automaticamente após a geração
/*/
Method newRelPV(cNumPedido, cFileName, cTitle, cFont, nFontSize, lAsk, lShowReport, lIsHtml) Class RelPV
	Default cFileName   := "RelatorioPedidoVenda"
	Default cTitle      := "Relatório de Pedido de Venda" 
	Default cFont       := "Arial"
	Default nFontSize   := 12
	Default lAsk  := .T.
	Default lShowReport := .F.
	Default lIsHtml     := .F.
	Default cNumPedido  := ""
			
	//Inicializacao dos atributos
	self:cNumPedido := cNumPedido
	self:cFileName  := cFileName
	self:oFont      := TFont():New(cFont,nFontSize,nFontSize,,.F.,,,,.T.,.F.)	
	self:oPdf       := IpPdfObject():newIpPdfObject(self:cFileName, , lShowReport)	
	self:lAsk := lAsk
	self:cQuery     := ""
	self:cHtml      := ""
	self:oSql       := IpSqlObject():newIpSqlObject() 		        
	//self:oPdf:setPortrait()
	self:lIsHtml      := lIsHtml
		    	  
	mkQuery(@self)     		     
	     
	//Verifica rotina automatica - Geração Automatica de Pedido de Venda    
	If FunName() == "MATA410"
		self:lIsAuto     := .T.
		self:lAsk  := .F.
		self:cNumPedido  := SC5->C5_NUM
		self:addWhere(" SC5.C5_NUM = " + self:cNumPedido)		
	endif

Return Self

/*/{Protheus.doc} ask

Método para configurar as definições do relatório de pedido de vendas e insere os filtros na query padrão

@type method 
@author Eduardo Silli Rufim
@since 27/06/2016
/*/
Method ask(cNumPedido) Class RelPV	
	Local aParams 
	Local cGrupoPerg := "REL_PV"
	Local lOk        := .T.
	
	Default cNumPedido := ""
	
	if(Empty(self:cNumPedido) .AND. Empty(cNumPedido))
		oParamBox := IpParamBoxObject():newIpParamBoxObject(cGrupoPerg)
		oParamBox:setTitle(self:cTitle)
		aParams   := addParams(@oParamBox)
		
		If (oParamBox:show())	
			addParamDinamicos(@self, @oParamBox, @aParams)
		else
			lOk := .F.
		endif
	else
		if !Empty(cNumPedido)
			self:cNumPedido := cNumPedido
		endif
		self:addWhere("SC5.C5_NUM = " + self:cNumPedido)
	endif
Return lOk

/*/{Protheus.doc} preview

Método para gerar o relatório PDF, e enviá-lo por e-mail caso algum e-mail tenha sido informado anteriormente

@type method 
@author Eduardo Silli Rufim
@since 27/06/2016
/*/
Method preview() Class RelPV
	Local lOk
	
	if(!self:oPdf:Setup(self:cTitle))
		//Cancelou a operação
		Return
	endif
				
	MsAguarde({|| lOk := runReport(@self)}, "Aguarde", "Gerando relatório ...")		
	
	if lOk
		MsgInfo("Relatório gerado com sucesso","Aviso")
	endif	
Return 

Method addField(cSelect) Class RelPV
	self:cQuery := StrTran(self:cQuery, "--##SELECT##--", ", " + cSelect + CRLF + "--##SELECT##--" + CRLF)
Return 

Method addFrom(cFrom) Class RelPV
	self:cQuery := StrTran(self:cQuery, "--##FROM##--", " " + cFrom + CRLF + "--##FROM##--" + CRLF)
Return 

Method addWhere(cWhere) Class RelPV 
	self:cQuery := StrTran(self:cQuery, "--##WHERE##--", " AND " + cWhere + CRLF + "--##WHERE##--" + CRLF)
Return

Method addOrderBy(cOrder) Class RelPV 
	self:cQuery := StrTran(self:cQuery, "--##ORDERBY##--", ", " + cOrder + CRLF + "--##ORDERBY##--" + CRLF)
Return

Method getTitle() Class RelPV
Return self:cTitle;	

Method setTitle(cTitle) Class RelPV
	self:cTitle := cTitle
Return	

Method getFileName() Class RelPV
Return self:cFileName
	
Method setFileName(cFileName) Class RelPV
	self:cFileName := cFileName
Return	

Method getFont() Class RelPV	
Return self:oFont

Method setFont(oFont) Class RelPV
	self:oFont := oFont
Return	

Method getAsk() Class RelPV
Return self:lAsk
	
Method setAsk(lAsk) Class RelPV
	self:lAsk := lAsk
Return 

Method getQuery() Class RelPV
Return self:cQuery

Method setQuery(cQuery) Class RelPV
	self:cQuery := cQuery
Return 

Method getHtml() Class RelPV
Return self:cHtml

Method setHtml(cHtml) Class RelPV
	self:cHtml := cHtml
Return

Method getNumPedido() Class RelPV
Return self:cNumPedido

Method setNumPedido(cNumPedido) Class RelPV
	self:cNumPedido := cNumPedido
Return 

Method isHtml() Class RelPV
Return self:lIsHtml

Method setIsHtml(lIsHtml) Class RelPV
	self:lIsHtml := lIsHtml
Return

Method getValue(cField) Class RelPV
Return self:oSql:getValue(cField)

//##########STATIC FUNCTIONS##########
//TODO atualizar protheus doc

/*/{Protheus.doc} addParams

Função para fazer a quebra da pagina devido a falta de espaço na pagina atual

@author Eduardo Silli Rufim
@since 27/06/2016

@param oParamBox, IpParamBoxObject, paramBox que receberá os dados dos parâmetros
   
@return Array 
/*/
Static Function addParams(oParamBox)
	Local oParam 		
	Local nCount
	Local aParams	 := {}
	//Local cGroupPerg := oParamBox:getId()
	
	//Filtros padrão
	oParam := IpParamObject():newIpParamObject("PEDIDO_DE", "get", "Pedido de", "C", 40, 03)
	oParam:setInitializer("1")
	oParam:setRequired(.T.)
	oParamBox:addParam(oParam)
	
	oParam := IpParamObject():newIpParamObject("PEDIDO_ATE", "get", "Pedido até", "C", 50, 09 )
	oParam:setInitializer("999999999")
	oParam:setRequired(.T.)	
	oParamBox:addParam(oParam)
	
	oParam := IpParamObject():newIpParamObject("DATA_DE", "get", "Data de", "D", 50, 09 )
	oParam:setRequired(.F.)	
	oParamBox:addParam(oParam)
	
	oParam := IpParamObject():newIpParamObject("DATA_ATE", "get", "Data ate", "D", 50, 09 )
	oParam:setRequired(.F.)	
	oParamBox:addParam(oParam)
	
	//aParams := {{"TIPO","Tipo","C",09,"C5_TIPO",.T.},{"LOJACLI","Loja Cliente","C",09,"C5_LOJACLI",.T.},{"EMISSAO_DE","Emissao De","D",09,"C5_EMISSAO",.T.},{"EMISSAO_ATE","Emissao Ate","D",09,"C5_EMISSAO",.T.}}		
	//Filtros dinamicos por ponto de entrada
	if ExistBlock("IPPVFILT")
		aParams := ExecBlock("IPPVFILT", , , aParams)		
		for nCount := 1 TO LEN(aParams) 		
			oParam := IpParamObject():newIpParamObject(aParams[nCount][1],"get",aParams[nCount][2],aParams[nCount][3],50,aParams[nCount][4],aParams[nCount][5])
			oParam:setRequired(aParams[nCount][6])
			oParamBox:addParam(oParam)
		Next nCount
	EndIf
	
Return aParams

Static Function mkQuery(oRelPV)
	if ExistBlock("IPPVSQL")
		//Ponto de entrada para alteração da query padrão
		oRelPV:cQuery := ExecBlock("IPPVSQL", , ,oRelPV:cQuery)
	else
		//Montagem da query padrao
		mkQueryPadrao(@oRelPV)
	endif	
Return

/*/{Protheus.doc} mkQueryPadrao

Método para criar a query padrão do relatório de pedido de vendas
 
@author Eduardo Silli Rufim
@since 27/06/2016
/*/
Static Function mkQueryPadrao(oRelPV)
			
    oRelPV:cQuery := " SELECT         "                                       + CRLF 
	oRelPV:cQuery += "    C5_NUM      "										  + CRLF	
	oRelPV:cQuery += "   ,C5_EMISSAO  "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_CONDPAG  "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DESC1    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DESC2    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DESC3    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_FRETE    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DESPESA  "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DESC4    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DATA1    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DATA2    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DATA3    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_DATA4    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_PARC1    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_PARC2    "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_PEDCLI   "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_PARC3    "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_ITEM     "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_PARC4    "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_CLIENTE  "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_LOJACLI  "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_TRANSP   "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_VEND1    "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_NUM      "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_PRODUTO  "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_DESCRI   "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_UM       "                                       + CRLF 
	oRelPV:cQuery += "   ,CONVERT(VARCHAR(8000),CONVERT(VARBINARY(8000),C5_MENNOTA)) C5_MENNOTA  " + CRLF   
	oRelPV:cQuery += "   ,C6_TES 	  "  									  + CRLF 
	oRelPV:cQuery += "   ,C6_QTDVEN   "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_PRCVEN   "                                       + CRLF 
	oRelPV:cQuery += "   ,C6_VALOR    "                                       + CRLF 
	oRelPV:cQuery += "   ,B1_IPI      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_END      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_COD      "                                       + CRLF 
	oRelPV:cQuery += "   ,C5_SEGURO   "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_NOME     "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_EMAIL    "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_MUN      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_EST      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_DDD      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_TEL      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_GRPTRIB  "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_TIPO     "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_FAX      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_CEP      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_CONTATO  "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_BAIRRO   "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_HPAGE    "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_CGC      "                                       + CRLF 
	oRelPV:cQuery += "   ,A1_INSCR    "                                       + CRLF 
	oRelPV:cQuery += "   ,B1_PICM     "                                       + CRLF 
	oRelPV:cQuery += "   ,B1_GRTRIB   "                                       + CRLF 
	oRelPV:cQuery += "   ,ISNULL(A3_NOME, '')   A3_NOME    "	              + CRLF            
	oRelPV:cQuery += "   ,ISNULL(A4_NOME, '')   A4_NOME    "                  + CRLF                     
	oRelPV:cQuery += "   ,ISNULL(E4_DESCRI, '') E4_DESCRI  "                  + CRLF                     
	oRelPV:cQuery += "   --##SELECT##-- "                                     + CRLF 
    oRelPV:cQuery += " FROM "                                                 + CRLF      
	oRelPV:cQuery += "   #RetSqlTab('SC5')# " 							 	  + CRLF
	oRelPV:cQuery += "   INNER JOIN #RetSqlTab('SC6')# ON 1=1         "       + CRLF             	  		
	oRelPV:cQuery += "        AND SC6.C6_FILIAL = '#xFilial('SC6')#'  "       + CRLF            	  
	oRelPV:cQuery += "        AND SC6.C6_NUM    = C5_NUM              "       + CRLF            	  
	oRelPV:cQuery += "        AND SC6.D_E_L_E_T_ = ' '                "       + CRLF            	  
	oRelPV:cQuery += "   INNER JOIN  #RetSqlTab('SA1')# ON 1=1        "       + CRLF            	  
	oRelPV:cQuery += "        AND SA1.A1_FILIAL = '#xFilial('SA1')#'  "       + CRLF            	  
	oRelPV:cQuery += "   	  	AND SA1.A1_COD    = C5_CLIENTE          "     + CRLF           	  
	oRelPV:cQuery += "   	  	AND SA1.A1_LOJA   = C5_LOJACLI          "     + CRLF           	  
	oRelPV:cQuery += "   	  	AND SA1.D_E_L_E_T_ = ' '                "     + CRLF           	  
	oRelPV:cQuery += "   INNER JOIN #RetSqlTab('SB1')#  ON 1=1        "       + CRLF            	  
	oRelPV:cQuery += "        AND SB1.B1_FILIAL = '#xFilial('SB1')#'  "       + CRLF            	  
	oRelPV:cQuery += "        AND SB1.B1_COD    = C6_PRODUTO          "       + CRLF            	  
	oRelPV:cQuery += "        AND SB1.D_E_L_E_T_ = ' '                "       + CRLF            	  
	oRelPV:cQuery += "   LEFT JOIN #RetSqlTab('SE4')# ON 1=1          "       + CRLF            	  
	oRelPV:cQuery += "        AND SE4.E4_FILIAL = '#+xFilial('SE4')#' "       + CRLF            	  
	oRelPV:cQuery += "        AND SE4.E4_CODIGO = C5_CONDPAG          "       + CRLF            	  
	oRelPV:cQuery += "        AND SE4.D_E_L_E_T_ = ' '                "       + CRLF            	  
	oRelPV:cQuery += "   LEFT JOIN #RetSqlTab('SA3')# ON 1=1          "       + CRLF             	  
	oRelPV:cQuery += "        AND SA3.A3_FILIAL = '#xFilial('SA3')#'  "       + CRLF            	  
	oRelPV:cQuery += "        AND SA3.A3_COD    = C5_VEND1            "       + CRLF            	  
	oRelPV:cQuery += "        AND SA3.D_E_L_E_T_ = ' '                "       + CRLF            	  
	oRelPV:cQuery += "   LEFT JOIN #RetSqlTab('SA4')# ON 1=1          "       + CRLF            	  
	oRelPV:cQuery += "        AND SA4.A4_FILIAL = '#xFilial('SA4')#'  "       + CRLF            	  
	oRelPV:cQuery += "        AND SA4.A4_COD    = C5_TRANSP           "       + CRLF               
	oRelPV:cQuery += "        AND SA4.D_E_L_E_T_ = ' '                "       + CRLF               
	oRelPV:cQuery += "   --##FROM##--                                 "       + CRLF                 
	oRelPV:cQuery += " WHERE  										"         + CRLF
	oRelPV:cQuery += "    1=1 										"         + CRLF	
	oRelPV:cQuery += "    AND SC5.C5_FILIAL = '#xFilial('SC5')#'      "       + CRLF
	oRelPV:cQuery += "    AND SC5.D_E_L_E_T_ = ' '                    "       + CRLF                   
	oRelPV:cQuery += "    --##WHERE##--                               "       + CRLF                   
	oRelPV:cQuery += " ORDER BY                                       "       + CRLF  
	oRelPV:cQuery += "    SC5.C5_NUM                                  "       + CRLF  
	oRelPV:cQuery += "    ,SC6.C6_ITEM                                "       + CRLF                 
	oRelPV:cQuery += "    --##ORDERBY##--                             "       + CRLF                   
	
Return

/*/{Protheus.doc} clearTags

Função para limpar as Tags da query antes de ser executada

@author Eduardo Silli Rufim
@since 27/06/2016
 
@param cQuery, String, query com as Tags --## ##-- a serem removidas

@return String, query sem as Tags
/*/
Static Function clearTags(cQuery)
	cQuery := StrTran(cQuery, "--##SELECT##--", "")
	cQuery := StrTran(cQuery, "--##FROM##--", "")
	cQuery := StrTran(cQuery, "--##WHERE##--", "")
	cQuery := StrTran(cQuery, "--##ORDERBY##--","")
Return cQuery

/*/{Protheus.doc} runReport

Função para executar a query e iniciar a montagem do relatório
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param oRelPV, RelPV, objeto do relatório do pedido de vendas
  
@return Lógico, se a operação foi realizada com sucesso (.T.) ou não (.F.)
/*/
Static Function runReport(oRelPV)  
	//Local cEmissao   := ""
	//Local nCount     := 0  
	Local lOk    	 := .F.
	Local cPedido    := ""

	oRelPV:oSql   := IpSqlObject():newIpSqlObject()
	oRelPV:cQuery := clearTags(oRelPV:cQuery)	
	oRelPV:cQuery := oRelPV:oSql:parseQuery(oRelPV:cQuery)

	//Grava a query para acompanhamento da pesquisa
	MemoWrite("\sql\" + oRelPV:cFileName + "-" + Dtos(Date()) + ".sql",oRelPV:cQuery)

	oRelPV:oSql:newAlias(oRelPV:cQuery)
	
	If !oRelPV:oSql:hasRecords()
		MsgSTOP("Não há registros para os parametros informados !")
		oRelPV:oSql:close()   
	else	
		oRelPV:oSql:goTop()	
		
		While !oRelPV:oSql:isEof()	
			oRelPV:oSql:setField("C5_EMISSAO", "D")		
			cPedido := oRelPV:getValue("C5_NUM")
							
			if(oRelPV:lIsHtml)
				gerarHtml(@oRelPV, cPedido) 
			else				
				gerarPdf(@oRelPV, cPedido)	
			endif
		enddo
						
		if(oRelPV:lIsHtml)
			lOk := .T. //TODO Implementar envio email
		else		
			lOk := oRelPV:oPdf:create(!Empty(oRelPV:oPdf:getEmail()))
		endif
	endif
	
	oRelPV:oSql:close()   
Return lOk

/*/{Protheus.doc} qtdeTotalItens

Função para retornar o número de itens por perdido 
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param cNum, String, numero do pedido

@return Numérico, quantidade de itens do pedido
/*/
Static Function qtdeTotalItens(cNum)
	Local   cDetailQuery 
	Local   nQtde  := 0
	Local   oSql   := IpSqlObject():newIpSqlObject() 	
	
	cDetailQuery := " SELECT COUNT(C6_ITEM) AS TOTAL "
	cDetailQuery += " FROM #RetSqlName('SC6')# "
	cDetailQuery += " WHERE 1=1 AND C6_NUM = '" + cNum + "' AND D_E_L_E_T_ = ' ' "
	
	cDetailQuery := oSql:parseQuery(cDetailQuery)
	oSql:newAlias(cDetailQuery)
	
	nQtde :=  oSql:getValue("TOTAL")
	
	oSql:close()
				
Return nQtde

/*/{Protheus.doc} Mm2Pix

Retirado metodo oPrint:nLogPixelX(), pois estava ocorrendo casos em clientes 
em que a linha impressa que utliza a funcao MM2PIX saia desconfigurada

@author Eduardo Silli Rufim
@since 27/06/2016
@version P12
 
@param nMm, Numérico, tamanho da String 

@return Numérico, tamanho em pixels
/*/
Static Function Mm2Pix(nMm)
Return (nMm * 300) / 25.4

/*/{Protheus.doc} getIpiValue

Função para calculo do IPI

@author Eduardo Silli Rufim
@since 27/06/2016
 
@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nOption, Numérico, opção para o cálculo (nOption = 1 (Alíquota) | nOption = 2 (Valor))

@return cIpiValue, valor calculado do IPI
/*/
Static Function getIpiValue(oRelPV, nOption)

	Local cIpiValue := ""
	Local nIpiValue := 0
	Local cCalcIPI  := AllTrim(Posicione("SF4",1,xFilial("SF4")+oRelPV:getValue("C6_TES"),"F4_IPI"))
	
	If nOption == 1
		cIpiValue := If(cCalcIPI == "S",AllTrim(Str(oRelPV:getValue("B1_IPI"),4,1)),"0,0")
	Else
		If cCalcIPI == "S"
			nIpiValue := (oRelPV:getValue("C6_VALOR") * ((oRelPV:getValue("B1_IPI"))/100))
		EndIf
		
		// Calcula o Valor Total do Pedido de Venda com IPI
		nTotaIpi += nIpiValue
		
		cIpiValue := AllTrim(Transform(nIpiValue,PesqPict("SD2","D2_VALIPI")))
	EndIf
	
Return cIpiValue

/*/{Protheus.doc} getIcmValue

/*/
Static Function getIcmValue(oRelPV, nOption)

	Local cIcmValue := ""
 	Local nIcmValue := 0
 	Local cCalcICM  := AllTrim(Posicione("SF4",1,xFilial("SF4")+oRelPV:getValue("C6_TES"),"F4_ICM"))
 	Local nAliqIcm  := getAliqICM(oRelPV)

	If nOption == 1
		cIcmValue := If(cCalcICM == "S",AllTrim(Str(nAliqIcm,4,1)),"0,0")
	Else
		If cCalcIcm == "S"
			nIcmValue := (oRelPV:getValue("C6_VALOR") * ((nAliqIcm)/100))
		EndIf
		
		nTotaIcm += nIcmValue
		
		cIcmValue := AllTrim(Transform(nIcmValue,PesqPict("SD2","D2_VALICM")))
	EndIf
	
Return cIcmValue

/*/{Protheus.doc} getAliqICM

Função para calculo da aliquota do ICMS
 
@author Eduardo Silli Rufim
@since 27/06/2016
 
@param oRelPV, RelPV, objeto do relatório de pedido de vendas
  
@return nAliqIcm, valor da aliquota calculada do ICMS
/*/
Static Function getAliqICM(oRelPV)

	Local cQuery   := ""
	Local nAliqIcm := 0
	Local oSqlICM  := IpSqlObject():newIpSqlObject()
	
	cQuery := " SELECT F7_SEQUEN,F7_ALIQINT,F7_ALIQEXT,F7_ALIQDST                    " + CRLF
	cQuery += " FROM "+RetSqlName("SF7")+" F7                                        " + CRLF
	cQuery += " WHERE F7_FILIAL  = '"+xFilial("SF7")+"' AND                          " + CRLF
	cQuery += "       F7_GRTRIB  = '"+oRelPV:getValue("B1_GRTRIB")+"' AND       	 " + CRLF
	cQuery += "       F7_GRPCLI  = '"+oRelPV:getValue("A1_GRPTRIB")+"' AND           " + CRLF
	cQuery += "       F7_EST     = '"+oRelPV:getValue("A1_EST")+"' AND               " + CRLF
	cQuery += "       F7_TIPOCLI = '"+oRelPV:getValue("A1_TIPO")+"' AND              " + CRLF
	cQuery += "       F7.D_E_L_E_T_ = ' '                                            " + CRLF
	
	oSqlICM:newAlias(cQuery)
	
	oSqlICM:goTop()	
	
	if !oSqlICM:isEof()
		nAliqIcm := oSqlICM:getValue("F7_ALIQINT")
	elseIf oRelPV:getValue("B1_PICM") > 0
		nAliqIcm := oRelPV:getValue("B1_PICM")
	else
		nAliqIcm := Val(Subs(alltrim(getmv("MV_ESTICM")),AT(oRelPV:getValue("A1_EST"),alltrim(getmv("MV_ESTICM")))+2,2))
	endIf
	
	oSqlICM:close() 
	
Return nAliqIcm

/*/{Protheus.doc} retDescontos

Calcula o somatorio dos descontos

@author Eduardo Silli Rufim
@since 27/06/2016
@version P12
 
@param oRelPV, RelPV, objeto do relatório de pedido de vendas
  
@return cDescontos, valor total dos descontos
/*/
Static Function retDescontos(oRelPV)
	Local cDescontos := ""

	If oRelPV:getValue("C5_DESC1") > 0
		cDescontos += AllTrim(Str(oRelPV:getValue("C5_DESC1"), 10, 2))
	EndIf
	
	If oRelPV:getValue("C5_DESC2") > 0
		If !Empty(cDescontos)
			cDescontos += " + "
		Endif
		cDescontos += AllTrim(Str(oRelPV:getValue("C5_DESC2"), 10, 2))
	EndIf
	
	If oRelPV:getValue("C5_DESC3") > 0
		If !Empty(cDescontos)
			cDescontos += " + "
		Endif
		cDescontos += AllTrim(Str(oRelPV:getValue("C5_DESC3"), 10, 2))
	EndIf
	
	If oRelPV:getValue("C5_DESC4") > 0
		If !Empty(cDescontos)
			cDescontos += " + "
		Endif
		cDescontos += AllTrim(Str(oRelPV:getValue("C5_DESC4"), 10, 2))
	EndIf
Return cDescontos

/*/{Protheus.doc} formatNum

Formata um numero para o picture desejado e atribui espaços a esquerda para evitar desalinhamentos no layout
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param cNumero, String, numero a ser formatado
@param [cPicture], String, picture que será usando Transform no cNumero
  
@return String, numero formatado de acordo com o parametro cPicutre e com espaços a esquerda
/*/
Static Function formatNum(cNumero, cPicture)
	if(!Empty(cPicture))
		cNumero := Transform(cNumero,cPicture)
	endif
	
	cNumero := PadL(AllTrim(cNumero), TAM_NUMEROS, " ")	
Return cNumero

//TODO criar protheus doc
/*
	aReg[1] = C - Apelido para o campo no ParamBox
	aReg[2] = C - Descrição do campo
	aReg[3] = C - Tipo da informação [C, D, N, etc]
	aReg[4] = N - Tamanho do Campo
	aReg[5] = C - Campo da tabela
	aReg[6] = L - Obrigatoriedade .T. ou .F.
*/
Static Function addParamDinamicos(oRelPV, oParamBox, aParams)
	Local aReg
	Local uValor
	Local i          
	Local uIntervalo
	Local cFiltro
	   
	//Adiciona filtros dinamicamente
	for i:=1 to LEN(aParams)
		aReg       := aParams[i]
		uValor     := AvKey(oParamBox:getValue(aReg[1]),aReg[5])
		cFiltro    := ""
		uIntervalo := ""
		if aReg[6] .OR. !Empty(uValor)
			DO CASE
			  CASE aReg[3] == "C"
			     oRelPV:addWhere(" " + aReg[5] + " = '"+ uValor +"' ")
			  CASE aReg[3] == "D"
			  	//Analisa o proximo parametro e avalia se o mesmo tambem eh uma data de mesmo campo, caso seja eh criado um filtro utilizando between
			  	 if(i < LEN(aParams))
			  	 	uIntervalo := aParams[i+1]
			  	 endif
			     if !Empty(uIntervalo)
			     	if(uIntervalo[3] == "D" .AND. aReg[5] == uIntervalo[5])
				     	uIntervalo := AvKey(oParamBox:getValue(uIntervalo[1]),uIntervalo[5])
				     	oRelPV:addWhere(" " + aReg[5] + " BETWEEN '" + uValor +"' AND '"+ uIntervalo + "' ")
				     	i++
				    else
				    	oRelPV:addWhere(" " + aReg[5] + " = '"+ uValor +"' ")
				    endif				 
				 else
				   	oRelPV:addWhere(" " + aReg[5] + " = '"+ uValor +"' ")
				 endif
			  OTHERWISE
			     oRelPV:addWhere(" " + aReg[5] + " = " + uValor +" ")
			ENDCASE						
		endif
	Next i
Return

//####################PDF#####################
Static Function gerarPdf(oRelPV, cPedido)					
	mkHeaderPdf(@oRelPV) 
	mkClientPdf(@oRelPV)
	montarDetalhes(@oRelPV, cPedido)	  			
	oRelPV:oSql:skip()    						
Return

/*/{Protheus.doc} mkHeaderPdf

Método para compor cabecalho padrão do relatorio
 
@author Eduardo Silli Rufim
@since 27/06/2016 
/*/
Static Function mkHeaderPdf(oRelPV) 
	Local nColuna     := 40 // Indica a posição da primeira coluna
	Local nLinha      := 0  // Controle de Linhas
	Local nHorzRes    := oRelPV:oPdf:oPrinter:nHorzRes()    
	Local margRight   := oRelPV:oPdf:oPrinter:nHorzRes()  - 100   
	Local numPedido     
	Local cDataRel       
	Local cFone       
	Local nomeCom     
	Local cAddress    
	Local cCnpj       
	Local cEmail            

	dbSelectArea("SM0")
	SM0->(dbseek(cEmPant + cFilant))
	                               
	numPedido   := "Pedido N° " + oRelPV:getValue("C5_NUM")      
	cDataRel    := "Data: " + Dtoc(oRelPV:getValue("C5_EMISSAO"))  
	cFone       := "Fone: " + AllTrim(SM0->M0_TEL)  
	nomeCom     := AllTrim(SM0->M0_NOMECOM)
	cAddress    := AllTrim(SM0->M0_ENDENT)+" "+AllTrim(SM0->M0_CIDENT)+"/"+AllTrim(SM0->M0_ESTENT)+" "+Left(AllTrim(SM0->M0_CEPENT),5) + "-" + Right(AllTrim(SM0->M0_CEPENT),3)
	cCnpj       := "CNPJ: " + AllTrim(Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")) + " - IE: " +  AllTrim(Transform(SM0->M0_INSC, "@R 999.999.999.999"))
	cEmail      := "E-mail: " + AllTrim(GetMV("MV_RELFROM"))   
	                           	
	oRelPV:oPdf:StartPage()
	                                                  
	oRelPV:oPdf:Say(nLinha  +  050,nColuna + margRight - Mm2Pix(len(nomeCom))  ,nomeCom    ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha  +  100,nColuna + margRight - Mm2Pix(len(cAddress)) ,cAddress   ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha  +  150,nColuna + margRight - Mm2Pix(len(cEmail))   ,cEmail     ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha  +  200,nColuna + margRight - Mm2Pix(len(cFone))    ,cFone      ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha  +  250,nColuna + margRight - Mm2Pix(len(cCnpj))    ,cCnpj      ,oRelPV:oFont,100,,,1)

	oRelPV:oPdf:Line(nLinha + 0310,nColuna ,nLinha + 0310,nColuna + nHorzRes + 200)
	oRelPV:oPdf:Line(nLinha + 0313,nColuna ,nLinha + 0313,nColuna + nHorzRes + 200)
	oRelPV:oPdf:Line(nLinha + 0410,nColuna ,nLinha + 0410,nColuna + nHorzRes + 200)
	oRelPV:oPdf:Line(nLinha + 0413,nColuna ,nLinha + 0413,nColuna + nHorzRes + 200)
	
	oRelPV:oPdf:Say(nLinha + 0370,nColuna             , numPedido ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0370,nColuna + margRight , cDataRel  ,oRelPV:oFont,100,,,1)
Return

/*/{Protheus.doc} mkClientPdf

Método para exibir detalhes do cliente
 
@author Eduardo Silli Rufim
@since 27/06/2016
/*/
Static Function mkClientPdf(oRelPV)
	Local cPhoneNumber := ""
	Local cCliente     := ""
	Local cCpfCnpj     := ""
	Local cCep         := ""
	Local cInscr       := ""
	Local nColuna      := 40 // Indica a posição da primeira coluna
	Local nLinha       := 0  // Controle de Linhas	
	Local nColCentral  := oRelPV:oPdf:oPrinter:nHorzRes() + 40
	//Local nHorzRes     := oRelPV:oPdf:oPrinter:nHorzRes()    
	//Local margRight    := oRelPV:oPdf:oPrinter:nHorzRes()  - 100        	                                       
	
	// Texto a Esquerda
	oRelPV:oPdf:Say(nLinha + 0460,nColuna,"Cliente" ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0510,nColuna,"E-mail"  ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0560,nColuna,"Endereço",oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0610,nColuna,"Cidade"  ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0660,nColuna,"TEL"     ,oRelPV:oFont,100,,,0)
	
	If Len(AllTrim(oRelPV:getValue("A1_CGC"))) > 11 
		oRelPV:oPdf:Say(nLinha + 0710,nColuna,"CNPJ",oRelPV:oFont,100,,,0)
	Else
		oRelPV:oPdf:Say(nLinha + 0710,nColuna,"CPF" ,oRelPV:oFont,100,,,0)
	EndIf	
	
	If Len(AllTrim(oRelPV:getValue("A1_CGC"))) > 11  
		cCpfCnpj := AllTrim(Transform(oRelPV:getValue("A1_CGC"),"@R 99.999.999/9999-99"))
	Else	
		cCpfCnpj := AllTrim(Transform(oRelPV:getValue("A1_CGC"),"@R 999.999.999-99"))
	EndIf
	
	cCliente     :=  oRelPV:getValue("A1_COD") + " - " + oRelPV:getValue("A1_NOME")
	cPhoneNumber := " (" + oRelPV:getValue("A1_DDD") + ") " + Left(oRelPV:getValue("A1_TEL"),4) + "-" + Substr(oRelPV:getValue("A1_TEL"),5,8)	
	
	oRelPV:oPdf:Say(nLinha + 0460,nColuna + 0190,": " + cCliente                    	             								,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0510,nColuna + 0190,": " + oRelPV:getValue("A1_EMAIL")                        					,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0560,nColuna + 0190,": " + oRelPV:getValue("A1_END")                          					,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0610,nColuna + 0190,": " + AllTrim(oRelPV:getValue("A1_MUN"))+"/"+oRelPV:getValue("A1_EST") 	,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0660,nColuna + 0190,": " + cPhoneNumber                                		 						,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0710,nColuna + 0190,": " + cCpfCnpj																	,oRelPV:oFont,100,,,0)
	
	// Texto Centralizado
	If Len(AllTrim(oRelPV:getValue("A1_INSCR"))) > 6
		cInscr := AllTrim(Transform(oRelPV:getValue("A1_INSCR"),"@R 999.999.999.999"))
	Else
		cInscr := AllTrim(oRelPV:getValue("A1_INSCR"))
	EndIf
	
	cCep   := Left(oRelPV:getValue("A1_CEP"),5) + "-" + Right(oRelPV:getValue("A1_CEP"),3)
	
	oRelPV:oPdf:Say(nLinha + 0510	,nColCentral / 2,"Contato" ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0560	,nColCentral / 2,"Bairro"  ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0610	,nColCentral / 2,"CEP"     ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0660	,nColCentral / 2,"I.E."    ,oRelPV:oFont,100,,,0)

	oRelPV:oPdf:Say(nLinha + 0510	,nColCentral / 2 + 0150,": " + oRelPV:getValue("A1_CONTATO") ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0560	,nColCentral / 2 + 0150,": " + oRelPV:getValue("A1_BAIRRO")  ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0610	,nColCentral / 2 + 0150,": " + cCep                             ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0660	,nColCentral / 2 + 0150,": " + cInscr   ,oRelPV:oFont,100,,,0)
		
Return

/*/{Protheus.doc} montarDetalhes

Método para exibir detalhes do pedido
 
@author Eduardo Silli Rufim
@since 27/06/2016
/*/
Static Function montarDetalhes(oRelPV, cPedido)
	Local nLinha        := 750
	Local nColuna       := 0 	
	Local i             := 1	
	Local nCont         := 0
	Local nHorzSize     := oRelPV:oPdf:oPrinter:nHorzRes()
	Local nVertSize     := oRelPV:oPdf:oPrinter:nVertRes()
	Local nPagina       := 1
	Local nTotalPaginas := 0
	
	Private nTotaIpi   := 0    // Controle do Valor Total do IPI
	Private nTotaIcm   := 0    // Controle do Valor Icm
	Private nTotal     := 0    // Controle do Valor Total Produtos
	Private nGeral     := 0	   // Controle do Valor Total Geral
	
	drawBoxDetalhe(oRelPV, nLinha, nColuna)
	drawBoxCabDetalhe(oRelPV, nLinha, nColuna)	
		
	//Quantidade total de detalhes do pedido	
	nCont   := qtdeTotalItens(cPedido)

	//Estima o numero de paginas do relatorio em relacao ao pedido
	nTotalPaginas := retTotalPaginas(oRelPV, nCont)
	
	//Imprime numero da primeira pagina
	oRelPV:oPdf:Say(nVertSize + 180 , nHorzSize - 200,"Página: " + Str(nPagina) + " / " + AllTrim(Str(nTotalPaginas))   ,oRelPV:oFont,100,,,1)	

	//Percorre os detalhes do pedido
	While i <= nCont .AND. cPedido == oRelPV:getValue("C5_NUM")   	
		nLinha += 50
		if(nLinha > nVertSize + 50)
			quebrarPagina(@oRelPV, @nLinha, @nColuna, @nPagina, nTotalPaginas) 	
		endif
		drawBoxDetalhe(oRelPV, nLinha, nColuna)
		drawInfoDetalhe(oRelPV, nLinha, nColuna)
		if(i < nCont)
			oRelPV:oSql:skip()
		endif
		i++
		
		nTotal += oRelPV:getValue("C6_VALOR") 
	EndDo
	nLinha += 50
	
	nGeral += nTotal; 
	       + oRelPV:getValue("C5_FRETE"); 
	       + oRelPV:getValue("C5_DESPESA"); 
           + oRelPV:getValue("C5_SEGURO");
	 	   + nTotaIcm;
	 	   + nTotaIpi
	
	montarTotal(@oRelPV, @nLinha, @nColuna, @nPagina, nTotalPaginas)	
	montarTrailer(@oRelPV, @nLinha, @nColuna, @nPagina, nTotalPaginas)
	
Return 

/*/{Protheus.doc} montarTotal

Método para exibir o totalizador do pedido

@author Eduardo Silli Rufim
@since 27/06/2016

@param nLinha, Numérico, número da linha em que as informações do totalizador serão impressas
@param nColuna, Numérico, coluna em que as informações do totalizador serão impressas
@param nPagina, Numérico, número da pagina em que o totalizador será impresso  
@param nTotalPaginas, Numérico, número total de paginas por pedido
/*/
Static Function montarTotal(oRelPV, nLinha, nColuna, nPagina, nTotalPaginas)
	Local nVertSize := oRelPV:oPdf:oPrinter:nVertRes()
	
	if(nLinha > nVertSize - 100)
		quebrarPagina(@oRelPV, @nLinha, @nColuna, @nPagina, nTotalPaginas) 	
	endif

	drawBoxTotalizador(oRelPV, nLinha, nColuna)
	drawInfoTotalizador(oRelPV, nLinha, nColuna)	
Return

/*/{Protheus.doc} montarTrailer

Método para exibir o trailer do relatorio
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param nLinha, Numérico, número da linha em que as informações do trailer serão impressas
@param nColuna, Numérico, coluna em que as informações do trailer serão impressas
@param nPagina, Numérico, número da pagina em que o trailer será impresso  
@param nTotalPaginas, Numérico, número total de paginas por pedido
/*/
Static Function montarTrailer(oRelPV, nLinha, nColuna, nPagina, nTotalPaginas)
	Local nVertSize  := oRelPV:oPdf:oPrinter:nVertRes()
	Local nHorzSize  := oRelPV:oPdf:oPrinter:nHorzRes() 		
	Local cDescontos := ""
	Local cCondPagamento := ""
	
	if(nLinha > nVertSize - 600)
		quebrarPagina(@oRelPV, @nLinha, @nColuna, @nPagina, nTotalPaginas) 	
	endif
	
	nLinha := nVertSize - 0270

	// Box Condicoes Gerais
	oRelPV:oPdf:Box(nVertSize - 0350,nColuna + 0040, nVertSize + 0010,nColuna + 2650)
	
	// Box para a Mensagem da Nota
	oRelPV:oPdf:Box(nVertSize + 30,nColuna + 0040, nVertSize + 0130  ,nColuna + 2650)
	
	// Titulo Centralizado
	oRelPV:oPdf:Say(nVertSize - 0320, nHorzSize / 2,"Informações Gerais",oRelPV:oFont,100,,,2)
	
	nLinha += 0050
	oRelPV:oPdf:Say(nLinha, nColuna + 0060,"Forma de Pagamento"  		  ,oRelPV:oFont,100,,,0)
	if(!Empty(oRelPV:getValue("C5_CONDPAG")))
		cCondPagamento := oRelPV:getValue("C5_CONDPAG")
	endif
	oRelPV:oPdf:Say(nLinha,nColuna + 0450,": " + cCondPagamento + " - " + oRelPV:getValue("E4_DESCRI")	                ,oRelPV:oFont,100,,,0)
	
	nLinha += 0050
	oRelPV:oPdf:Say(nLinha,nColuna + 0060,"Transportadora" 			  											        ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha,nColuna + 0450,": (" + oRelPV:getValue("C5_TRANSP") + ") " + oRelPV:getValue("A4_NOME")  ,oRelPV:oFont,100,,,0)
	
	nLinha += 0050
	oRelPV:oPdf:Say(nLinha,nColuna + 0060,"Nº do Pedido Cliente" 		 											        ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha,nColuna + 0450,": " + oRelPV:getValue("C6_PEDCLI")								            ,oRelPV:oFont,100,,,0)
	
	oRelPV:oPdf:Say(nLinha, nHorzSize / 2,"Vendedor" 			          											        ,oRelPV:oFont,100)
	oRelPV:oPdf:Say(nLinha, nHorzSize / 2 + 0250,": (" + oRelPV:getValue("C5_VEND1") + ") " + oRelPV:getValue("A3_NOME")   ,oRelPV:oFont,100)
    
    nLinha += 0050
    
    cDescontos := retDescontos(oRelPV)
	If !Empty(cDescontos)
		oRelPV:oPdf:Say(nLinha,nColuna + 0060,"Descontos"   ,oRelPV:oFont,100,,,0)
		oRelPV:oPdf:Say(nLinha,nColuna + 0450,": " + cDescontos,oRelPV:oFont,100,,,0)
	EndIf
        
    nLinha += 0130
    oRelPV:oPdf:Say(nLinha,nColuna + 0060,"Obs"                         								   ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha,nColuna + 0200,".: " + Substr(oRelPV:getValue("C5_MENNOTA"),1,100)         ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha,nColuna + 0200,Space(03) + Substr(oRelPV:getValue("C5_MENNOTA"),101,100)   ,oRelPV:oFont,100,,,0)
		
Return

/*/{Protheus.doc} quebrarPagina

Método para fazer a quebra da pagina devido a falta de espaço na pagina atual

@author Eduardo Silli Rufim
@since 27/06/2016
 
@param nLinha, Numérico, número da linha em que a quebra irá imprimir os detalhes do pedido considerando header e detalhes do cliente
@param nColuna, Numérico, número da coluna em que a quebra irá imprimir os detalhes do pedido considerando header e detalhes do cliente
@param nPagina, Numérico, número da nova pagina
@param nTotalPaginas, Numérico, número total de paginas por pedido
@param lDetalhe, Lógico, indica se o cabecalho da tabela de detalhes do pedido será exibido (.T.) ou não (.F.) na nova pagina
/*/
Static Function quebrarPagina(oRelPV, nLinha, nColuna, nPagina, nTotalPaginas, lDetalhe)
	Local nHorzSize := oRelPV:oPdf:oPrinter:nHorzRes()
	Local nVertSize := oRelPV:oPdf:oPrinter:nVertRes()
	
	Default lDetalhe := .T.
	
	oRelPV:oPdf:EndPage()
	mkHeaderPdf(@oRelPV)
	mkClientPdf(@oRelPV)	
	nLinha  := 750
	nColuna := 0
	if(lDetalhe)
		drawBoxDetalhe(oRelPV, nLinha, nColuna)	
		drawBoxCabDetalhe(oRelPV, nLinha, nColuna)
		nLinha += 50
	endif	
	nPagina++
	oRelPV:oPdf:Say(nVertSize + 180 , nHorzSize - 200,"Página: " + Str(nPagina) + " / " + AllTrim(Str(nTotalPaginas))   ,oRelPV:oFont,100,,,1)		
Return

/*/{Protheus.doc} drawBoxDetalhe

Função para inserir apenas o box contendo as linhas de detalhe dos pedidos  
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nLinha, Numérico, linha inicial em que o box será inserido
@param nColuna, Numérico, coluna inicial em que o box será inserido
/*/
Static Function drawBoxDetalhe(oRelPV, nLinha, nColuna)
	oRelPV:oPdf:Box(nLinha,nColuna + 0040, nLinha + 0050,nColuna + 2650)

	oRelPV:oPdf:Line(nLinha,nColuna + 0120,nLinha + 0050,nColuna + 0120)
	oRelPV:oPdf:Line(nLinha,nColuna + 0440,nLinha + 0050,nColuna + 0440) 
	oRelPV:oPdf:Line(nLinha,nColuna + 1190,nLinha + 0050,nColuna + 1190) 
	oRelPV:oPdf:Line(nLinha,nColuna + 1270,nLinha + 0050,nColuna + 1270) 
	oRelPV:oPdf:Line(nLinha,nColuna + 1430,nLinha + 0050,nColuna + 1430) 
	oRelPV:oPdf:Line(nLinha,nColuna + 1730,nLinha + 0050,nColuna + 1730)
	oRelPV:oPdf:Line(nLinha,nColuna + 2030,nLinha + 0050,nColuna + 2030) 
	oRelPV:oPdf:Line(nLinha,nColuna + 2200,nLinha + 0050,nColuna + 2200)
Return

/*/{Protheus.doc} drawBoxCabDetalhe

Função para inserir os titulos do cabecalho dos detalhes dos pedidos
 
@author Eduardo Silli Rufim
@since 27/06/2016
 
@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nLinha, Numérico, linha inicial em que o box será inserido
@param nColuna, Numérico, coluna inicial em que o box será inserido  
/*/
Static Function drawBoxCabDetalhe(oRelPV, nLinha, nColuna)
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 0050,"Item"     ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 0140,"Produto"  ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 0460,"Descrição",oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1210,"UM"       ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1290,"Qtd."     ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1450,"Preço R$" ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1750,"Total R$" ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 2050,"% ICMS"   ,oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 2220,"% IPI"    ,oRelPV:oFont,100,,,0)
return

/*/{Protheus.doc} drawInfoDetalhe

Função para inserir as informações dos detalhes dos pedidos

@author Eduardo Silli Rufim
@since 27/06/2016

@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nLinha, Numérico, linha inicial em que o box será inserido
@param nColuna, Numérico, coluna inicial em que o box será inserido
/*/
Static Function drawInfoDetalhe(oRelPV, nLinha, nColuna)
	Local cPrcVen
	Local cValor

	cPrcVen := formatNum(Transform(oRelPV:getValue("C6_PRCVEN"),PesqPict("SC6","C6_PRCVEN")))
	cValor  := formatNum(Transform(oRelPV:getValue("C6_VALOR") ,PesqPict("SC6","C6_VALOR")))
	
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 0050,AllTrim(oRelPV:getValue("C6_ITEM"))                ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 0140,AllTrim(oRelPV:getValue("C6_PRODUTO"))             ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 0460,Substr(AllTrim(oRelPV:getValue("C6_DESCRI")),1,30) ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1210,AllTrim(oRelPV:getValue("C6_UM"))                  ,oRelPV:oFont,100,,,0) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1120,formatNum(Str(oRelPV:getValue("C6_QTDVEN")))       ,oRelPV:oFont,100,,,1) 
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1410,cPrcVen                             				     ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1690,cValor                              				     ,oRelPV:oFont,100,,,1)
	
	//TODO adicionar pontos de entrada para impostos
	//Aliquotas
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 2000,formatNum(getIcmValue(oRelPV, 1))       			 ,oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0040,nColuna + 1880,formatNum(getIpiValue(oRelPV, 1))        			 ,oRelPV:oFont,100,,,1)
	
	//Valores
	getIcmValue(oRelPV, 2)
	getIpiValue(oRelPV, 2)
Return

/*/{Protheus.doc} drawBoxTotalizador

Função para inserir os titulos dos totalizadores do relatorio
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nLinha, Numérico, linha inicial em que o box será inserido
@param nColuna, Numérico, coluna inicial em que o box será inserido  
/*/
Static Function drawBoxTotalizador(oRelPV, nLinha, nColuna)
	//Box
	oRelPV:oPdf:Box(nLinha  + 0060,nColuna + 0080,nLinha + 0210,nColuna + 0860)
	oRelPV:oPdf:Box(nLinha  + 0060,nColuna + 0960,nLinha + 0160,nColuna + 1740)
	oRelPV:oPdf:Box(nLinha  + 0060,nColuna + 1840,nLinha + 0160,nColuna + 2620)
	
	//Separadores Verticais
	oRelPV:oPdf:Line(nLinha + 0060,nColuna + 0470,nLinha + 0210,nColuna + 0470)
	oRelPV:oPdf:Line(nLinha + 0060,nColuna + 1350,nLinha + 0160,nColuna + 1350)
	oRelPV:oPdf:Line(nLinha + 0060,nColuna + 2230,nLinha + 0160,nColuna + 2230)	
	
	//Separadores Horizontais
	oRelPV:oPdf:Line(nLinha + 0110,nColuna + 0080,nLinha + 0110,nColuna + 0860)
	oRelPV:oPdf:Line(nLinha + 0160,nColuna + 0080,nLinha + 0160,nColuna + 0860)		
	oRelPV:oPdf:Line(nLinha + 0110,nColuna + 0960,nLinha + 0110,nColuna + 1740)
	oRelPV:oPdf:Line(nLinha + 0110,nColuna + 1840,nLinha + 0110,nColuna + 2620)	
	
	//Titulos
	oRelPV:oPdf:Say(nLinha + 0095,nColuna + 0100,"Valor Frete",oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0145,nColuna + 0100,"Valor Seguro",oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0195,nColuna + 0100,"Outras Despesas",oRelPV:oFont,100,,,0)	

	oRelPV:oPdf:Say(nLinha + 0095,nColuna + 0980,"Valor Total ICMS",oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0145,nColuna + 0980,"Valor Total IPI",oRelPV:oFont,100,,,0)
	
	oRelPV:oPdf:Say(nLinha + 0095,nColuna + 1860,"Valor Produtos",oRelPV:oFont,100,,,0)
	oRelPV:oPdf:Say(nLinha + 0145,nColuna + 1860,"Valor Total",oRelPV:oFont,100,,,0) 
Return

/*/{Protheus.doc} drawInfoTotalizador

Função para inserir as informações dos totalizadores do relatório  
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nLinha, Numérico, linha inicial em que as informções serão inseridas
@param nColuna, Numérico, coluna inicial em que as informções serão inseridas
/*/
Static Function drawInfoTotalizador(oRelPV, nLinha, nColuna)

	oRelPV:oPdf:Say(nLinha + 0095,nColuna + 510," " + formatNum(oRelPV:getValue("C5_FRETE"),PesqPict("SC5","C5_FRETE")),oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0145,nColuna + 510," " + formatNum(oRelPV:getValue("C5_SEGURO"),PesqPict("SC5","C5_SEGURO")),oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0195,nColuna + 510," " + formatNum(oRelPV:getValue("C5_DESPESA"),PesqPict("SC5","C5_DESPESA")),oRelPV:oFont,100,,,1)
	
	oRelPV:oPdf:Say(nLinha + 0095,nColuna + 1390," " + formatNum(nTotaIcm,"@E 9,999,999.99"),oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0145,nColuna + 1390," " + formatNum(nTotaIpi,"@E 9,999,999.99"),oRelPV:oFont,100,,,1)	
	
	oRelPV:oPdf:Say(nLinha + 0095,nColuna + 2270," " + formatNum(nTotal,PesqPict("SC6","C6_VALOR")),oRelPV:oFont,100,,,1)
	oRelPV:oPdf:Say(nLinha + 0145,nColuna + 2270," " + formatNum(nGeral,"@E 9,999,999.99"),oRelPV:oFont,100,,,1)	
	
Return

/*/{Protheus.doc} retTotalPaginas

Retorna uma estimativa do numero total de paginas por pedido
 
@author Eduardo Silli Rufim
@since 27/06/2016

@param oRelPV, RelPV, objeto do relatório de pedido de vendas
@param nQtdeDetalhes, Numérico, quantidade total de itens do pedido
  
@return nPaginas, numero total de paginas por pedido
/*/
Static Function retTotalPaginas(oRelPV, nQtdeDetalhes)
	Local nPaginas
	Local detPorPagina := 49 //Numero maximo de detalhes que cabem na pagina
	Local nTamTrailer  := 0.2 //Proporcao da pagina destinada ao totalizador e trailer
	
	nPaginas := Ceiling(nQtdeDetalhes / detPorPagina  + nTamTrailer)  //Considerando espaço para o totalizador e o trailer

Return nPaginas

//################HTML#################

Static Function gerarHtml(oRelPV, cPedido)	
	if ExistBlock("IPPVHTML")
		ExecBlock("IPPVHTML", , , {oRelPV:cHtml, oRelPV:oSql})
	else
		gerarHtmlPadrao(@oRelPV, cPedido)
	endif
	
	MemoWrite("\sql\ HTML -" + Dtos(Date()) + ".html",oRelPV:cHtml)		
Return

Static Function gerarHtmlPadrao(oRelPV, cPedido)
	oRelPV:cHtml += dwHtmlHeader(oRelPV)
	oRelPV:cHtml += dwHtmlClient(oRelPV)
	oRelPV:cHtml += dwHtmlDetalhes(oRelPV, cPedido)
	oRelPV:cHtml += dwHtmlTotal(oRelPV)	
	oRelPV:cHtml += dwHtmlTrailer(oRelPV)	
Return

Static Function dwHtmlHeader(oRelPV)
	Local cHtml 	  := ""
	Local numPedido   := oRelPV:getValue("C5_NUM")      
	Local cDataRel    := Dtoc(oRelPV:getValue("C5_EMISSAO"))  
	Local cFone       := AllTrim(SM0->M0_TEL)  
	Local nomeCom     := AllTrim(SM0->M0_NOMECOM)
	Local cAddress    := AllTrim(SM0->M0_ENDENT)+" "+AllTrim(SM0->M0_CIDENT)+"/"+AllTrim(SM0->M0_ESTENT)+" "+Left(AllTrim(SM0->M0_CEPENT),5) + "-" + Right(AllTrim(SM0->M0_CEPENT),3)
	Local cCnpj       := AllTrim(Transform(SM0->M0_CGC, "@R 99.999.999/9999-99")) + " - IE: " +  AllTrim(Transform(SM0->M0_INSC, "@R 999.999.999.999"))
	Local cEmail      := AllTrim(GetMV("MV_RELFROM"))   
	
	cHtml += '<table border="0" width="100%">'
	cHtml += '	<tbody>'
	cHtml += '		<tr>'
	cHtml += '			<td width="53%" height="99">'
	cHtml += '				<div align="left">'
	cHtml += '					<img src="LOGO_EMAIL" alt="" width="252" height="88" />'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="47%">'
	cHtml += '				<div align="left">'
	cHtml += '					<p>'
	cHtml += '						<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '							<strong>'
	cHtml += '								 ' + nomeCom
	cHtml += '								<br />'
	cHtml += '								 ' + cAddress
	cHtml += '								<br />'
	cHtml += '								 E-mail: ' + cEmail
	cHtml += '								<br />'
	cHtml += '								 Fone: ' + cFone
	cHtml += '								<br />'
	cHtml += '								 CNPJ: ' + cCnpj
	cHtml += '							</strong>'
	cHtml += '						</span>'
	cHtml += '					</p>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '	</tbody>'
	cHtml += '</table>'
	cHtml += '<hr />'
	cHtml += '<table border="0" width="100%">'
	cHtml += '	<tbody>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: medium;">'
	cHtml += '					<strong>'
	cHtml += '						 Pedido N° ' + numPedido
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<div align="right">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: medium;">'
	cHtml += '						<strong>'
	cHtml += '							 Data: ' + cDataRel
	cHtml += '						</strong>'
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '	</tbody>'
	cHtml += '</table>'
	cHtml += '<hr />'
	
Return cHtml

Static Function dwHtmlClient(oRelPV)
	Local cHtml        := ""
	Local cCabCpfCnpj 
	Local cCpfCnpj
	Local cInscr      
	Local cCliente 	   := oRelPV:getValue("A1_COD") + " - " + oRelPV:getValue("A1_NOME")
	Local cPhoneNumber := " (" + oRelPV:getValue("A1_DDD") + ") " + Left(oRelPV:getValue("A1_TEL"),4) + "-" + Substr(oRelPV:getValue("A1_TEL"),5,8)
	Local cCidade      := AllTrim(oRelPV:getValue("A1_MUN"))+"/"+oRelPV:getValue("A1_EST")
	Local cCep         := Left(oRelPV:getValue("A1_CEP"),5) + "-" + Right(oRelPV:getValue("A1_CEP"),3) 	
	
	If Len(AllTrim(oRelPV:getValue("A1_CGC"))) > 11 
		cCpfCnpj := AllTrim(Transform(oRelPV:getValue("A1_CGC"),"@R 99.999.999/9999-99"))
		cCabCpfCnpj := "CNPJ :"
	Else
		cCpfCnpj := AllTrim(Transform(oRelPV:getValue("A1_CGC"),"@R 999.999.999-99"))
		cCabCpfCnpj := "CPF :"
	EndIf	
	
	If Len(AllTrim(oRelPV:getValue("A1_INSCR"))) > 6
		cInscr := AllTrim(Transform(oRelPV:getValue("A1_INSCR"),"@R 999.999.999.999"))
	Else
		cInscr := AllTrim(oRelPV:getValue("A1_INSCR"))
	EndIf

	cHtml += '<table border="0" width="100%">'
	cHtml += '	<tbody>'
	cHtml += '		<tr>'
	cHtml += '			<td width="12%">'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Cliente:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td width="39%">'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cCliente
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td width="9%">'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					  '
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td width="40%">'
	cHtml += '				 '
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 E-Mail:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + oRelPV:getValue("A1_EMAIL")
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Contato:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + oRelPV:getValue("A1_CONTATO")
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Endereço:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + oRelPV:getValue("A1_END")
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Bairro:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + oRelPV:getValue("A1_BAIRRO")
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Cidade:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cCidade
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Cep:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cCep
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Tel:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cPhoneNumber
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 I.E.:'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cInscr
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 ' + cCabCpfCnpj
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cCpfCnpj
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '	</tbody>'
	cHtml += '</table>'
	cHtml += '</br>'

Return cHtml

Static Function dwHtmlDetalhes(oRelPV, cPedido)
	Local cHtml := ""
			
	Local cValor
	Local cPrcVen
	 
	//Cabecalho 
	cHtml += '<table border="1" width="100%">'
	cHtml += '	<tbody>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Item'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Produto'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Descrição'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 UM'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Qtde.'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Valor Unit.'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 Valor Total'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 % ICMS'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					<strong>'
	cHtml += '						 % IPI'
	cHtml += '					</strong>'
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	
	//Itens
	While cPedido == oRelPV:getValue("C5_NUM") 
		
		cValor  := formatNum(Transform(oRelPV:getValue("C6_VALOR") ,PesqPict("SC6","C6_VALOR")))
		cPrcVen := formatNum(Transform(oRelPV:getValue("C6_PRCVEN"),PesqPict("SC6","C6_PRCVEN")))
	
		cHtml += '		<tr>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + oRelPV:getValue("C5_NUM") 
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + AllTrim(oRelPV:getValue("C6_PRODUTO"))
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + Substr(AllTrim(oRelPV:getValue("C6_DESCRI")),1,30)
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + AllTrim(oRelPV:getValue("C6_UM"))
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + formatNum(Str(oRelPV:getValue("C6_QTDVEN")))
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + cPrcVen
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + cValor
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + formatNum(getIcmValue(oRelPV, 1))  
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '			<td>'
		cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
		cHtml += '					 ' + formatNum(getIpiValue(oRelPV, 1)) 
		cHtml += '				</span>'
		cHtml += '			</td>'
		cHtml += '		</tr>'
		
		oRelPV:oSql:skip()
	enddo
	
	//Finaliza Detalhes
	cHtml += '	</tbody>'
	cHtml += '</table>'
	cHtml += '</br>'
	 
Return cHtml

Static Function dwHtmlTotal(oRelPV)
	Local cHtml := ""
	
	Local cSeguro
	Local cDespesa
	Local cFrete
	
	cFrete   := formatNum(oRelPV:getValue("C5_FRETE"),PesqPict("SC5","C5_FRETE"))
	cSeguro  := formatNum(oRelPV:getValue("C5_SEGURO"),PesqPict("SC5","C5_SEGURO"))
	cDespesa := formatNum(oRelPV:getValue("C5_DESPESA"),PesqPict("SC5","C5_DESPESA"))	
	
	cHtml += '<table border="0" width="100%">'
	cHtml += '	<tbody>'
	cHtml += '		<tr>'
	cHtml += '			<td width="18%">'
	cHtml += '				<div align="left">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						<strong>'
	cHtml += '							 Valor Frete:'
	cHtml += '						</strong>'
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="26%">'
	cHtml += '				<div align="right">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 ' + cFrete
	cHtml += '					</span>'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						  '
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="8%">'
	cHtml += '				 '
	cHtml += '			</td>'
	cHtml += '			<td colspan="2">'
	cHtml += '				<div align="left">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						<strong>'
	cHtml += '							 Valor da Despesa:'
	cHtml += '						</strong>'
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="24%">'
	cHtml += '				<div align="right">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 ' + cDespesa
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td width="18%">'
	cHtml += '				<div align="left">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						<strong>'
	cHtml += '							  Valor Seguro:'
	cHtml += '						</strong>'
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="26%">'
	cHtml += '				<div align="right">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 ' + cSeguro
	cHtml += '					</span>'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						  '
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="8%">'
	cHtml += '				 '
	cHtml += '			</td>'				
	cHtml += '			<td colspan="2">'
	cHtml += '				<div align="left">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						<strong>'
	cHtml += '							 Valor Total:'
	cHtml += '						</strong>'
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '			<td width="24%">'
	cHtml += '				<div align="right">'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 INSERIR VALOR TOTAL'
	cHtml += '					</span>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '	</tbody>'
	cHtml += '</table>'
	cHtml += '<hr />'

Return cHtml

Static Function dwHtmlTrailer(oRelPV)
	Local cHtml := ""
	
	Local cTransportadora 
	Local cVendedor
	Local cCondPagamento := ""
	
	cTransportadora := "(" + oRelPV:getValue("C5_TRANSP") + ") " + oRelPV:getValue("A4_NOME")
	cVendedor       := "(" + oRelPV:getValue("C5_VEND1") + ") " + oRelPV:getValue("A3_NOME")
		
	if(!Empty(oRelPV:getValue("C5_CONDPAG")))
		cCondPagamento := oRelPV:getValue("C5_CONDPAG")
	endif	
	
	cCondPagamento += " - " + oRelPV:getValue("E4_DESCRI")
		
	cHtml += '<table border="0" width="100%">'
	cHtml += '	<tbody>'
	cHtml += '		<tr>'
	cHtml += '			<td colspan="5" width="50%">'
	cHtml += '				<div align="center">'
	cHtml += '					<strong>'
	cHtml += '						<span style="font-family: Arial, Helvetica, sans-serif; font-size: medium;">'
	cHtml += '							 Informações Gerais'
	cHtml += '						</span>'
	cHtml += '					</strong>'
	cHtml += '				</div>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td colspan="1" width="25%">'
	cHtml += '				<p>'
	cHtml += '					<strong>'
	cHtml += '						<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '							 Forma de Pagamento:'
	cHtml += '						</span>'
	cHtml += '					</strong>'
	cHtml += '				</p>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cCondPagamento
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td colspan="1" width="25%">'
	cHtml += '				<p>'
	cHtml += '					<strong>'
	cHtml += '						<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '							 Transportadora:'
	cHtml += '						</span>'
	cHtml += '					</strong>'
	cHtml += '				</p>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cTransportadora
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<strong>'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 Descontos %:'
	cHtml += '					</span>'
	cHtml += '				</strong>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + retDescontos(oRelPV)
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<strong>'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 Nº do Pedido Cliente:'
	cHtml += '					</span>'
	cHtml += '				</strong>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + oRelPV:getValue("C6_PEDCLI")
	cHtml += '				</span>'
	cHtml += '			</td>		
	cHtml += '			<td colspan="2" width="25%">'
	cHtml += '				<strong>'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 Vendedor:'
	cHtml += '					</span>'
	cHtml += '				</strong>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + cVendedor
	cHtml += '				</span>'
	cHtml += '			</td>'	'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td>'
	cHtml += '				<strong>'
	cHtml += '					<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '						 Obs:'
	cHtml += '					</span>'
	cHtml += '				</strong>'
	cHtml += '			</td>'
	cHtml += '			<td>'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					 ' + Substr(oRelPV:getValue("C5_MENNOTA"),1,100)
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '		<tr>'
	cHtml += '			<td colspan="2">'
	cHtml += '				<span style="font-family: Arial, Helvetica, sans-serif; font-size: small;">'
	cHtml += '					' + Substr(oRelPV:getValue("C5_MENNOTA"),101,100)
	cHtml += '				</span>'
	cHtml += '			</td>'
	cHtml += '		</tr>'
	cHtml += '	</tbody>'
	cHtml += '</table>'
	cHtml += '<hr />'
	cHtml += '<div style="page-break-after: always"></div>' //Quebra de pagina para iniciar novo pedido
	
Return cHtml
