#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} NEWGEN01

Coletanea de funçoes genericas e gatilhos

@author Brito
@since 07/12/2022

/*/

User Function NewFator()

    Local aArea      := GetArea()
    Local cCodLegado := ""
    Local cCodUni    := ""
    Local nFator     := 0

    cCodLegado := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZCOD')
    cCodUni    := TMP1->CK_UM
    //Z01_FILIAL+Z01_PRODUT+Z01_UNID+Z01_UNIREF
    DbSelectArea("Z01")
    DbSetOrder(2)

    If DbSeek(FWxFilial("Z01") + cCodLegado + cCodUni )
        nFator := Z01->Z01_FATOR
    EndIf

    RestArea(aArea)

Return nFator


/*/{Protheus.doc} NewCalPrc

Calcula preço em cima no tipo de unidade de medida e fator cadastrado no produto

@author Brito
@since 07/12/2022

/*/

User Function NewCalPrc()

    Local aArea      := GetArea()
    Local nPrcUnit   := 0
    Local nQtd       := 0 
    Local nPesoReal  := 0
    Local cUnidade   := ""
    Local nCustoGer  := 0
    Local nMargem    := 0

    cUnidade  := TMP1->CK_UM
    nQtd      := TMP1->CK_QTDVEN
    nPesoReal := U_NewFator()

    nCustoGer := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZCUST')
    nMargem   := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZMAR1')

    If Alltrim(cUnidade) == "BR"
        nPrcUnit := nPesoReal * (nCustoGer * nMargem)
    ElseIf Alltrim(cUnidade) == "MT"
        nPrcUnit := nPesoReal * (nCustoGer * nMargem)
    ElseIf Alltrim(cUnidade) == "KG"
        nPrcUnit := nCustoGer * nMargem
    Else 
        nPrcUnit := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZCUST')
    EndIf

    RestArea(aArea)

Return nPrcUnit


/*/{Protheus.doc} NewPeso

Multiplica o peso real pela quantidade digitada

@author Brito
@since 07/12/2022

/*/

User Function NewPeso()

    Local aArea     := GetArea()
    Local nQtd      := TMP1->CK_QTDVEN
    Local nPesoReal := U_NewFator()
    Local nPesoTot  := 0

    If nPesoReal == 0
        nPesoTot := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_PESO')
    Else 
        nPesoTot := nQtd * nPesoReal
    EndIf

    RestArea(aArea)

Return nPesoTot

/*/{Protheus.doc} NewKick

Calcula novo preço a  partir de um chute (peso a nao ser faturado)

@author Brito
@since 07/12/2022

/*/

User Function NewKick()

    Local aArea      := GetArea()
    Local nPrcUnit   := 0
    Local nQtd       := 0 
    Local nKick      := 0
    Local cUnidade   := ""
    Local nCustoGer  := 0
    Local nMargem    := 0

    cUnidade  := TMP1->CK_UM
    nQtd      := TMP1->CK_QTDVEN
    nKick     := TMP1->CK_ZZKICK

    nCustoGer := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZCUST')
    nMargem   := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZMAR1')

    If  Alltrim(cUnidade) == "KG"
        nPrcUnit := nCustoGer * nMargem
    Else 
        Alert("Permitido apenas para unidade de medida KG")
    EndIf

    RestArea(aArea)

Return nPrcUnit

/*/{Protheus.doc} VldNewVlr

Valida novo valor a partir do chute digitado

@author Brito
@since 07/12/2022

/*/

User Function VldNewVlr()

    Local aArea     := GetArea()
    Local nQtd      := TMP1->CK_QTDVEN
    Local nPreco    := TMP1->CK_PRCVEN
    Local nValor    := 0

    nValor := nQtd * nPreco

    RestArea(aArea)

Return nValor

/*/{Protheus.doc} NewMarkup

Calcula Markup do produto digitado

@author Brito
@since 08/12/2022

/*/

User Function NewMarkup()

    Local aArea     := GetArea()
    Local nPrcVen   := 0
    Local nCustGer  := 0
    Local nMarkup   := 0 

    nPrcVen  := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZPRC1')
    nCustGer := Posicione('SB1',1, xFilial("SB1") + TMP1->CK_PRODUTO , 'B1_ZZCUST')

    nMarkup := ((nPrcVen - nCustGer) / nCustGer) * 100

    RestArea(aArea)

Return nMarkup

/*/{Protheus.doc} NewPerKi

Calcula percentual de chute (kick)

@author Brito
@since 12/12/2022

/*/

User Function NewPerKi()

    Local aArea     := GetArea()
    Local nPer      := 0
    Local nChute    := TMP1->CK_ZZKICK
    Local nPesoReal := TMP1->CK_ZZPSRE
    Local nQuant    := TMP1->CK_QTDVEN

    nPer := nChute - (nPesoReal * nQuant)
    nPer := nPer / (nPesoReal * nQuant)
    nPer := nPer * 100

    RestArea(aArea)

Return nPer

/*/{Protheus.doc} NEWGENASP

Retira aspas duplas oriundas do arquivo csv de importação

@author Brito
@since 27/12/2022

/*/

User Function NEWGENASP(cStr)

    Local aArea     := GetArea()
    
    cStr := StrTran(cStr,'"','')

    RestArea(aArea)

Return cStr
