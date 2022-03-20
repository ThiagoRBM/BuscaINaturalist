### Buscar dados no INaturalist (usando a API)
### 
### 

library(httr)
library(readxl)
library(stringr)
library(dplyr)

## ao invés dos nomes de espécies, famílias ou outro nível taxonômico, as buscas são feitas pelo código
## que os mesmos recebem. Antes de fazer a busca de observações / ocorrências, encontrar o número (chamado
## de id na API do site) do que queremos encontrar

NomesInat <- read_excel("GitInat/NomesInat.xlsx") ## tabela que contenha uma coluna com os taxa que temos interess

#### NAO MEXER DAQUI PARA BAIXO, SERÁ INDICADO QUANDO MEXER DE NOVO
#### 
#### 
#### 

BuscaIDtaxa= function(tabela, colunaNomes){

busca= tabela[[colunaNomes]]

url= paste0("https://api.inaturalist.org/v1/taxa?q=",
            busca) %>% 
  gsub(" ", "%20", .)


get= lapply(url, httr::GET)

res= lapply(get, function(x) httr::content(x, encoding = "UTF-8",
                                                type = 'application/json'))

lista= vector("list", length= length(res))
for(i in 1:length(res)){
  
  taxon= res[[i]][["results"]][[1]][["name"]]
  buscaIDs= res[[i]][["results"]][[1]][["id"]]
  nivelTaxonomico= res[[i]][["results"]][[1]][["rank"]]
  observacoes= res[[i]][["results"]][[1]][["observations_count"]]
 
  lista[[i]]["Busca"]= taxon
  lista[[i]]["IDbusca"]= buscaIDs
  lista[[i]]["NivelTaxonomico"]= nivelTaxonomico
  lista[[i]]["NObs"]= observacoes
  
  if(i == length(lista)){
    
    tabRes= data.frame(do.call("rbind", lista))
    
  }
  
}

return(tabRes)
print("tabela gerada")

}


### MEXER NA LINHA ABAIXO:


buscaIDs= BuscaIDtaxa(NomesInat, "taxon") 
## substituir nomesInat pelo nome da coluna com os nomes dos taxa na tabela que estiver usando (SEM ASPAS).
## substituir "taxon" pelo nome da coluna que tiver os nomes dos taxa de interesse (COM ASPAS). 
## Nomes de diferentes níveis taxonômicos podem estar misturados na mesma colua (e.g., espécie, família
## gênero tudo um abaixo do outro, como no exemplo da tabela)
## A funcao gera uma tabela com informações da busca feita, como número de observações e 
## o ID dos taxa (independente do nível taxonômico), na coluna "IDbusca"


##### o mesmo que acontece para os taxa, de a busca ser feita com numeros de ID ao inves dos nomes propriamente
##### ditos, acontece tambem para a localizacao. Cada pais, cidade e etc tem um numero proprio.
##### Por isso, caso se queira buscar por observacoes por algum pais é melhor que se saiba o número do mesmo.
##### A funcao abaixo permite obter o ID de determinada regiao.
##### 
##### 
#### NAO MEXER DAQUI PARA BAIXO, SERÁ INDICADO QUANDO MEXER DE NOVO
#### 
#### 
#### 

local= c("brasilia", "para de minas", "São Paulo", "sao jose dos campos", "toronto")


BuscaIDlocal= function(localidades){
  
  busca= localidades %>% 
    iconv(., from="latin2", to="ASCII//TRANSLIT") %>% 
    str_to_lower(.)
  
  url= paste0("https://api.inaturalist.org/v1/search?q=",
              busca, 
              "&sources=places") %>% 
    gsub(" ", "%20", .)
  
  
  get= lapply(url, httr::GET)
  
  res= lapply(get, function(x) httr::content(x, encoding = "UTF-8",
                                             type = 'text'))
  
  lista= vector("list", length= length(res))
  for(i in 1:length(res)){
    
    nome= busca[i]
    
    resultado= iconv(res[[i]], from="UTF-8", to="ASCII//TRANSLIT") %>% 
      str_to_lower(.)
    buscaIDs= str_extract(resultado, paste0('(?<=\"type\":\"place\")\\s*(.*?)\\s*(?=\"uuid\")')) %>% 
      str_extract(., paste0('(?<=\"id\":).*')) %>% 
      str_extract(., "[0-9.]+")
    
    lista[[i]]["Busca"]= nome
    lista[[i]]["IDbusca"]= buscaIDs
    #lista[[i]]["NivelTaxonomico"]= nivelTaxonomico
    #lista[[i]]["NObs"]= observacoes
    #names(lista)= c("Busca", "IDbusca", "NivelTaxonomico","Nobs")
    
    if(i == length(lista)){
      
      tabRes= data.frame(do.call("rbind", lista))
      
    }
    
  }
  
  return(tabRes)
  print("tabela gerada")
  
}

### MEXER NA LINHA ABAIXO:


buscaLocal= BuscaIDlocal(local) ### substituir "local" por nomes de cidades ou paises. Pode ser no formato que
## está no exemplo ou uma coluna de uma tabela (colocando no formato tabela$coluna)
## uma tabela com o nome da localização e o respectivo ID é gerada

### Agora, com as IDs dos taxa que queremos, podemos buscar pelas outras informações, como coordandas das 
### observações postadas no INat e outras.

#### NAO MEXER DAQUI PARA BAIXO, SERÁ INDICADO QUANDO MEXER DE NOVO (funcao longa, ir para o fim do script)
#### 
#### 
#### 


BuscaObservacoes= function(nomesLocalidade, nomesTaxa){
  
  locTax= expand.grid(local= nomesLocalidade, taxa= nomesTaxa) %>% 
    data.frame()
  
  url= paste0("https://api.inaturalist.org/v1/observations?place_id=",
              locTax$local, 
              "&taxon_id=",
              locTax$taxa,
              "&hrank=family&per_page=200&order=desc&order_by=created_at")
  
  
  BuscaINat= lapply(url, httr::GET)
  PagINat= lapply(BuscaINat, function(x) httr::content(x, encoding = "UTF-8",
                                                       type = 'application/json'))
  
  print("Conectando e baixando dados")
  
  pg= sapply(PagINat, function(x) as.numeric(x[["total_results"]]))
  mx= sapply(PagINat, function(x) as.numeric(x[["per_page"]]))[1]
  
  
  listaCompleta= vector("list", length= length(pg)) ## em pg[pg>0] ajustando para o tamanho
  ## da lista contar apenas as paginas que tenham tido ocorrência (com comprimento > 0 )
  for(x in 1:length(pg)) {
    if(pg[x] == 0) {
      listaCompleta[[x]] = paste0("Sem ocorrencia da especie: ",
                                  locTax$taxa[x],
                                  " na localidade: ",
                                  locTax$local[x])
    } else{
      lista = vector("list", length = ceiling(pg[x] / mx))
      for (i in 1:ceiling(pg[x] /
                          mx)) { ## API do INAT limita a 200 ocorrências por página
        ## nesse loop, o número de páginas necessário para a espécie
        ## é calculado com base no número de observações encontradas
        
        url2 = httr::GET(
          paste0(
            "https://api.inaturalist.org/v1/observations?place_id=",
            locTax$local[x],
            "&taxon_id=",
            locTax$taxa[x],
            "&hrank=family&page=",
            i,
            "&per_page=200&order=desc&order_by=created_at"
          )
        ) ## aqui, montando uma URL para cada página
        
        busca = httr::content(url2, encoding = "UTF-8", type = 'application/json')[["results"]]
        
        
        listaInterna = vector("list", length = length(busca))
        for (l in 1:length(busca)) { ## nesse loop, uma tabela é feita para cada página
          
          if (length(busca[[l]][["ofvs"]]) > 0) { ## aqui, pegando informações como espécie hospedeira 
            ## interassante para organismos como abelhas ou parasitas
            vecOfvs = unlist(busca[[l]][["ofvs"]])
            NOfvs = names(vecOfvs)
            
            taxNome = vecOfvs[grep("(taxon\\.name)", NOfvs, ignore.case =
                                     TRUE)]
            taxID = vecOfvs[grep("(taxon\\.min_species_taxon_id)",
                                 NOfvs,
                                 ignore.case = TRUE)]
          } else{
            taxNome = NA
            taxID = NA
            
          }
          
          df = data.frame(
            quality_grade = ifelse(length(busca[[l]][["quality_grade"]]) > 0,
                                   busca[[l]][["quality_grade"]],
                                   NA),
            time_observed_at = ifelse(length(busca[[l]][["time_observed_at"]]) >
                                        0,
                                      busca[[l]][["time_observed_at"]],
                                      NA),
            id = ifelse(length(busca[[l]][["id"]]) >
                          0,
                        busca[[l]][["id"]],
                        NA),
            uuid = ifelse(length(busca[[l]][["uuid"]]) >
                            0,
                          busca[[l]][["uuid"]],
                          NA),
            identifications_most_agree = ifelse(length(busca[[l]][["identifications_most_agree"]]) >
                                                  0,
                                                busca[[l]][["identifications_most_agree"]],
                                                NA),
            species_guess = ifelse(length(busca[[l]][["species_guess"]]) >
                                     0,
                                   busca[[l]][["species_guess"]],
                                   NA),
            tags = ifelse(length(busca[[l]][["tags"]]) >
                            0,
                          busca[[l]][["tags"]],
                          NA),
            created_at = ifelse(length(busca[[l]][["created_at"]]) >
                                  0,
                                busca[[l]][["created_at"]],
                                NA),
            description = ifelse(length(busca[[l]][["description"]]) >
                                   0,
                                 busca[[l]][["description"]],
                                 NA),
            uri = ifelse(length(busca[[l]][["uri"]]) >
                           0,
                         busca[[l]][["uri"]],
                         NA),
            community_taxon_id = ifelse(length(busca[[l]][["community_taxon_id"]]) >
                                          0,
                                        busca[[l]][["community_taxon_id"]],
                                        NA),
            long = ifelse(length(busca[[l]][["geojson"]]) >
                            0,
                          busca[[l]][["geojson"]][[1]][[1]],
                          NA),
            lat = ifelse(length(busca[[l]][["geojson"]]) >
                           0,
                         busca[[l]][["geojson"]][[1]][[2]],
                         NA),
            taxon = ifelse(length(busca[[l]][["taxon"]]) >
                          0,
                        busca[[l]][["taxon"]]$name,
                        NA),
            pais = ifelse(length(busca[[l]][["place_ids"]]) >
                            0,
                          busca[[l]][["place_ids"]][[1]],
                          NA),
            estado = ifelse(length(busca[[l]][["place_ids"]]) >
                              0,
                            busca[[l]][["place_ids"]][[2]],
                            NA),
            cidade = ifelse(length(busca[[l]][["place_ids"]]) >
                              0,
                            busca[[l]][["place_ids"]][[3]],
                            NA),
            
            hospedeira.nome = ifelse(length(taxNome) >
                                       0, taxNome, NA),
            
            hospedeira.cod = ifelse(length(taxID) >
                                      0, taxID, NA),
            
            flores = if (length(busca[[l]][["annotations"]]) > 0) {
              ifelse(length(grep("12\\|13", unlist(busca[[l]][["annotations"]]))) > 0,
                     grep("12\\|13", unlist(busca[[l]][["annotations"]]), value = TRUE),
                     NA)
            } else{
              NA
            },
            frutos = if (length(busca[[l]][["annotations"]]) > 0) {
              ifelse(length(grep("12\\|14", unlist(busca[[l]][["annotations"]]))) > 0,
                     grep("12\\|14", unlist(busca[[l]][["annotations"]]), value = TRUE),
                     NA)
            } else{
              NA
            },
            botao = if (length(busca[[l]][["annotations"]]) > 0) {
              ifelse(length(grep("12\\|15", unlist(busca[[l]][["annotations"]]))) > 0,
                     grep("12\\|15", unlist(busca[[l]][["annotations"]]), value = TRUE),
                     NA)
            } else{
              NA
            }
          )
          
          names(df)[7] = "tags"
          
          listaInterna[[l]] = df
          
        }
        
        lista[[i]] = do.call("rbind", listaInterna)
        
        cat(
          paste0(
            "Local ID: ",
            locTax$local[x],
            "\n",
            " Taxon ID: ",
            locTax$taxa[x],
            "\n",
            " pag. ",
            i,
            " de ",
            ceiling(pg[x] / mx)
          ),
          "\n\n\n"
        )
        
        if (i == ceiling(pg[x] /
                         mx)) {
          listaTab = do.call("rbind", lista)
        }
        
      }
      
      listaCompleta[[x]] = listaTab
    }
    
    
    
  }
  
  
  TabFinal= do.call("rbind", listaCompleta) %>% 
    mutate(flores= ifelse(!is.na(flores), "Sim", NA),
           frutos= ifelse(!is.na(frutos), "Sim", NA),
           botao= ifelse(!is.na(botao), "Sim", NA))
  return(TabFinal)
  
}


### MEXER NA LINHA ABAIXO:

tabelaTeste= BuscaObservacoes(buscaLocal$IDbusca, buscaIDs$IDbusca)
