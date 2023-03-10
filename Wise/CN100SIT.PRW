#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} CN100SIT

Ponto de entrada, que valida a alteração de status do contrato

@author		Thierry / Brito
@since		02/02/2023
@version	12.1.33
/*/

User Function CN100SIT()

Local cAtu   := PARAMIXB[1]
Local cSitua := PARAMIXB[2]// Situação atual do contrato.

U_CN1ORCRE()

/*If cAtu == DEF_SELAB    
  MsgAlert ('Situacao alterada de Em Elaboracao')
EndIf// Nova situação do contrato;

If cDst == DEF_SVIGE    
  MsgAlert ('Situacao alterada para Vigente')
EndIf*/

Return


/*/{Protheus.doc} CN1ORCRE

Busca saldo orçado x realizado, validando a inclusão do contrato

@author		Thierry / Brito
@since		02/02/2023
@version	12.1.33
/*/

User Function CN1ORCRE(cConta, cCusto, cItem, dDtIni, dDtFim)

  Local cQuery := ""
  Local cTmp   := GetNextAlias()

  cQuery := "SELECT MASTER.CODCONTACONTABIL "
  cQuery += ",MASTER.CTARES "
  cQuery += ",MASTER.DESCRICAOCONTACONTABIL "
  cQuery += ",MASTER.TIPOCONTA "
  cQuery += ",MASTER.CENTRODECUSTO "
  cQuery += ",MASTER.CCRES "
  cQuery += ",MASTER.DESCRICAOCENTROCUSTO "
  cQuery += ",MASTER.TIPOCENTROCUSTO "
  cQuery += ",MASTER.CODIGOCONTASUPERIOR "
  cQuery += ",MASTER.SUBCATEGORIA "
  cQuery += ",MASTER.DESCRICAOCONTASUPERIOR "
  cQuery += ",MASTER.DIADOSALDO "
  cQuery += ",MASTER.ORCADO "
  cQuery += ",MASTER.REALIZADO " 
  cQuery += ",IIF(MASTER.REALIZADO > 0,(MASTER.ORCADO - MASTER.REALIZADO) / MASTER.REALIZADO,0)  DESVIO "
  cQuery += "FROM "
  cQuery += "(SELECT CT1_CONTA      CODCONTACONTABIL, "
  cQuery += "CT1_RES                CTARES, "
  cQuery += "CT1_DESC01             DESCRICAOCONTACONTABIL, "
  cQuery += "CT1_CLASSE             TIPOCONTA, "
  cQuery += "ARQ2.CTT_CUSTO         CENTRODECUSTO, " 
  cQuery += "ARQ2.CTT_RES           CCRES, "
  cQuery += "ARQ2.CTT_DESC01        DESCRICAOCENTROCUSTO, "
  cQuery += "ARQ2.CTT_CLASSE        TIPOCENTROCUSTO, "
  cQuery += "ARQ2.CTT_CCSUP         CODIGOCONTASUPERIOR, "
  cQuery += "ARQ_INFO.CTT_DESC01    DESCRICAOCONTASUPERIOR, "
  cQuery += "CQ3_DATA               DIADOSALDO, "
  cQuery += "(SELECT ( (COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1) "
  cQuery += "FROM " + RetSqlName("CQ3") + " CQ3 "
  cQuery += "WHERE  CQ3_FILIAL = '" + xFilial("CQ3") + "' "
  cQuery += "AND CQ3_MOEDA = '01' "
  cQuery += "AND CQ3_TPSALD = '0' "
  cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
  cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
  cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
  cQuery += "AND CQ3_DATA > '20210101' "
  cQuery += "AND CQ3_CONTA = '" + cConta + "' "
  cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
  cQuery += "AND CQ3.D_E_L_E_T_ = ' ') AS ORCADO, "
  cQuery += "(SELECT ( COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1 "
  cQuery += "FROM " + RetSqlName("CQ3") + " CQ3 "
  cQuery += "WHERE  CQ3_FILIAL = '01' "
  cQuery += "AND CQ3_MOEDA = '01' "
  cQuery += "AND CQ3_TPSALD = '1' "
  cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
  cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
  cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
  cQuery += "AND CQ3_DATA > '20210101' "
  cQuery += "AND CQ3_CONTA = '" + cConta + "' "
  cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
  cQuery += "AND CQ3.D_E_L_E_T_ = ' ') AS REALIZADO "
  cQuery += "FROM  " + RetSqlName("CT1") + " ARQ, "
  cQuery += "" + RetSqlName("CQ3") + " ARQ1, "
  cQuery += "" + RetSqlName("CTT") + " ARQ2 "
  cQuery += "LEFT JOIN " + RetSqlName("CTT") + " ARQ_INFO "
  cQuery += "ON 1 = 1 "
  cQuery += "AND ARQ_INFO.CTT_FILIAL = ARQ2.CTT_FILIAL "
  cQuery += "AND ARQ_INFO.CTT_CUSTO = ARQ2.CTT_CCSUP "
  cQuery += "AND ARQ_INFO.D_E_L_E_T_ = ' ' "
  cQuery += "WHERE  ARQ2.CTT_FILIAL = '" + xFilial("CTT") + "' "
  cQuery += "AND ARQ2.CTT_CLASSE = '2' "
  cQuery += "AND ARQ2.CTT_CUSTO = '" + cCusto + "' "
  cQuery += "AND ARQ.CT1_FILIAL = '" + xFilial("CT1") + "' "
  cQuery += "AND ARQ.CT1_CONTA = '" + cConta + "'
  cQuery += "AND ARQ.CT1_CLASSE = '2' "
  cQuery += "AND ARQ.D_E_L_E_T_ = ' ' "
  cQuery += "AND ARQ2.D_E_L_E_T_ = ' ' "
  cQuery += "AND ARQ1.CQ3_CONTA = ARQ.CT1_CONTA "
  cQuery += "AND ARQ1.CQ3_CCUSTO = ARQ2.CTT_CUSTO "
  cQuery += "AND ( (SELECT ( COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1 "
  cQuery += "FROM " + RetSqlName("CQ3") + " CQ3 "
  cQuery += "WHERE  CQ3_FILIAL = '" + xFilial("CQ3") + "' "
  cQuery += "AND CQ3_MOEDA = '01' "
  cQuery += "AND CQ3_TPSALD = '0' "
  cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
  cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
  cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
  cQuery += "AND CQ3_CONTA = '" + cConta + "' "
  cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
  cQuery += "AND CQ3_DATA > '20210101' "
  cQuery += "AND CQ3.D_E_L_E_T_ = ' ') <> 0 "
  cQuery += "OR (SELECT ( COALESCE(Sum(CQ3_CREDIT) - Sum(CQ3_DEBITO),0) ) * -1 "
  cQuery += "FROM  " + RetSqlName("CQ3") + " CQ3 "
  cQuery += "WHERE  CQ3_FILIAL = '" + xFilial("CQ3") + "' "
  cQuery += "AND CQ3_MOEDA = '01' "
  cQuery += "AND CQ3_TPSALD = '1' "
  cQuery += "AND CQ3_CONTA = ARQ.CT1_CONTA "
  cQuery += "AND CQ3_CCUSTO = ARQ2.CTT_CUSTO "
  cQuery += "AND CQ3_CONTA = '" + cConta + "' "
  cQuery += "AND CQ3_CCUSTO = '" + cCusto + "' "
  cQuery += "AND CQ3_DATA = ARQ1.CQ3_DATA "
  cQuery += "AND CQ3_DATA > '20210101' "
  cQuery += "AND CQ3.D_E_L_E_T_ = ' ') <> 0 ) "
  cQuery += "GROUP  BY CT1_CONTA, "
  cQuery += "CT1_RES, "
  cQuery += "CT1_DESC01, "
  cQuery += "CT1_CLASSE, "
  cQuery += "CT1_CTASUP, "
  cQuery += "ARQ2.CTT_CUSTO, "
  cQuery += "ARQ2.CTT_RES, "
  cQuery += "ARQ2.CTT_DESC01, "
  cQuery += "ARQ2.CTT_CLASSE, "
  cQuery += "ARQ2.CTT_CCSUP, "
  cQuery += "CQ3_DATA, "
  cQuery += "ARQ_INFO.CTT_DESC01 "
  cQuery += ") MASTER"    

  cQuery := ChangeQuery(cQuery)

  DbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQuery),cTmp,.F.,.F.) 

  (cTmp)->(DbGoTop())
  
  While (cTmp)->(!EOF())

    (cTmp)->(DbSkip())

  EndDo 

  (cTmp)->(DbCloseArea())

Return




