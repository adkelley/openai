import gleam/json.{type Json}
import gleam/option.{type Option}
import openai/types/helpers

pub type FileSearch {
  FileSearch(
    // type: "file_search"
    /// The IDs of the vector stores to search.
    vector_store_ids: List(String),
    /// A filter to apply.
    filters: Option(Filter),
    /// The maximum number of results to return. This number should be between
    /// 1 and 50 inclusive.
    max_number_results: Option(Int),
    /// Ranking options for search.
    ranking_options: RankingOptions,
  )
}

pub fn encode_file_search(file_search: FileSearch) -> Json {
  [
    #("type", json.string("file_search")),
    #("vector_store_ids", json.array(file_search.vector_store_ids, json.string)),
    #("ranking_options", encode_ranking_options(file_search.ranking_options)),
  ]
  |> helpers.encode_option(
    "max_number_results",
    file_search.max_number_results,
    json.int,
  )
  |> helpers.encode_option("filters", file_search.filters, encode_filters)
  |> json.object
}

pub type Filter {
  FilterComparisonFilter(ComparisonFilter)
  CompoundFilter(List(ComparisonFilter))
}

fn encode_filters(filter: Filter) -> Json {
  case filter {
    FilterComparisonFilter(comparison_filter) ->
      encode_comparison_filter(comparison_filter)
    CompoundFilter(filters) ->
      json.object([
        #("type", json.string("and")),
        #("filters", json.array(filters, encode_comparison_filter)),
      ])
  }
}

/// A filter used to compare a specified attribute key to a given value using
/// a defined comparison operation.
pub type ComparisonFilter {
  ComparisonFilter(
    /// The key to compare against the value.
    key: String,
    /// Specifies the comparison operator: eq, ne, gt, gte, lt, lte, in, nin.
    type_: ComparisonOperators,
    /// The value to compare against the attribute key.
    value: UnionMembers(Value),
  )
}

fn encode_comparison_filter(comparison_filter: ComparisonFilter) -> Json {
  json.object([
    #("key", json.string(comparison_filter.key)),
    #("type", encode_comparison_operator(comparison_filter.type_)),
    #("value", encode_value(comparison_filter.value)),
  ])
}

/// Specifies the comparison operator: eq, ne, gt, gte, lt, lte, in, nin.
pub type ComparisonOperators {
  Eq
  Ne
  Gt
  Gte
  Lt
  Lte
  In
  Nin
}

fn encode_comparison_operator(comparison_operator: ComparisonOperators) -> Json {
  case comparison_operator {
    Eq -> json.string("eq")
    Ne -> json.string("ne")
    Gt -> json.string("gt")
    Gte -> json.string("gte")
    Lt -> json.string("lt")
    Lte -> json.string("lte")
    In -> json.string("in")
    Nin -> json.string("nin")
  }
}

pub type Value

pub fn value(union_members: UnionMembers(any)) -> UnionMembers(Value) {
  case union_members {
    UnionMember0 -> UnionMember0
    UnionMember1 -> UnionMember1
    UnionMember2 -> UnionMember2
    UnionMember3(ArrayUnionMember0) -> UnionMember3(ArrayUnionMember0)
    UnionMember3(ArrayUnionMember1) -> UnionMember3(ArrayUnionMember1)
  }
}

pub type UnionMembers(any) {
  // String
  UnionMember0
  // Number
  UnionMember1
  // Boolean
  UnionMember2
  // Array String or Number
  UnionMember3(ArrayUnionMembers)
}

fn encode_value(value_members: UnionMembers(Value)) -> Json {
  case value_members {
    UnionMember0 -> json.string("")
    UnionMember1 -> json.float(0.0)
    UnionMember2 -> json.bool(False)
    UnionMember3(array_value_members) ->
      case array_value_members {
        ArrayUnionMember0 -> json.array([], json.string)
        ArrayUnionMember1 -> json.array([], json.float)
      }
  }
}

pub type ArrayUnionMembers {
  // String
  ArrayUnionMember0
  // Number
  ArrayUnionMember1
}

pub type RankingOptions {
  RankingOptions(
    /// Weights that control how reciprocal rank fusion balances semantic
    /// embedding matches versus sparse keyword matches when hybrid search is
    /// enabled.
    hybrid_search: Weights,
    /// The ranker to use for the file search.
    ranker: Ranker,
    /// The score threshold for the file search, a number between 0 and 1.
    /// Numbers closer to 1 will attempt to return only the most relevant
    /// results, but may return fewer results.
    score_threshold: Option(Float),
  )
}

fn encode_ranking_options(ranking_options: RankingOptions) -> Json {
  [
    #(
      "hybrid_search",
      json.object([
        #(
          "embedding_weight",
          json.float(ranking_options.hybrid_search.embedding_weight),
        ),
        #("text_weight", json.float(ranking_options.hybrid_search.text_weight)),
      ]),
    ),
    #("ranker", encode_file_search_ranker(ranking_options.ranker)),
  ]
  |> helpers.encode_option(
    "score_threshold",
    ranking_options.score_threshold,
    json.float,
  )
  |> json.object
}

pub type Weights {
  Weights(embedding_weight: Float, text_weight: Float)
}

pub type Ranker {
  RankerAuto
  // "auto"
  RankerDefault
  // "default-2024-11-15"
}

fn encode_file_search_ranker(ranker: Ranker) -> Json {
  case ranker {
    RankerAuto -> json.string("auto")
    RankerDefault -> json.string("default-2024-11-15")
  }
}

pub type Status {
  InProgress
  Searching
  Completed
  Incomplete
  Failed
}

pub type Attributes

pub fn attributes(
  attributes_members: UnionMembers(any),
) -> UnionMembers(Attributes) {
  case attributes_members {
    UnionMember0 -> UnionMember0
    UnionMember1 -> UnionMember1
    UnionMember2 -> UnionMember2
    _ -> panic as "file_search: invalid Attributes"
  }
}

pub type FileSearchCall {
  FileSearchCall(
    // type: "file_search_call"
    /// The unique ID of the file search tool call.
    id: String,
    /// The queries used to perform the file search.
    queries: List(String),
    /// The status of the file search call.
    status: Status,
    /// The results returned by the file search call.
    results: List(ResultDef),
  )
}

// TODO Write the encoders and decoders.

pub type ResultDef {
  ResultDef(
    /// Attributes attached to the search result.
    attributes: #(String, UnionMembers(Attributes)),
    /// The ID of the file that matched.
    file_id: Option(String),
    /// The filename of the matching file.
    filename: Option(String),
    /// The relevance score of the result, from 0 to 1.
    score: Option(Float),
    /// The matching text returned for this result.
    text: String,
  )
}

pub type InputOutputItem {
  Input(FileSearchCall)
  Output(FileSearchCall)
}
