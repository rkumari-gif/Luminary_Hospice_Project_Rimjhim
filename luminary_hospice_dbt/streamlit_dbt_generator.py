import streamlit as st
from snowflake.snowpark.context import get_active_session
import re

session = get_active_session()

st.set_page_config(page_title="Luminary Hospice - dbt Architecture Generator", layout="wide")

st.title("Luminary Hospice — dbt Architecture Generator")
st.markdown("Connect to your Snowflake data sources and auto-generate a full dbt medallion architecture.")

if "selected_tables_meta" not in st.session_state:
    st.session_state.selected_tables_meta = []
if "generated_code" not in st.session_state:
    st.session_state.generated_code = {}


@st.cache_data(ttl=300)
def get_databases():
    df = session.sql("SHOW DATABASES").collect()
    return sorted([row["name"] for row in df])


@st.cache_data(ttl=300)
def get_schemas(database):
    df = session.sql(f'SHOW SCHEMAS IN DATABASE "{database}"').collect()
    return sorted([row["name"] for row in df])


@st.cache_data(ttl=300)
def get_tables(database, schema):
    df = session.sql(f'SHOW TABLES IN "{database}"."{schema}"').collect()
    return [{"name": row["name"], "kind": "TABLE"} for row in df]


@st.cache_data(ttl=300)
def get_views(database, schema):
    df = session.sql(f'SHOW VIEWS IN "{database}"."{schema}"').collect()
    return [{"name": row["name"], "kind": "VIEW"} for row in df]


@st.cache_data(ttl=300)
def get_columns(database, schema, table_name):
    df = session.sql(f'DESCRIBE TABLE "{database}"."{schema}"."{table_name}"').collect()
    return [{"name": row["name"], "type": row["type"]} for row in df]


def snake_case(name):
    s = re.sub(r"[^a-zA-Z0-9]", "_", name)
    s = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", s)
    s = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", s)
    s = re.sub(r"_+", "_", s).strip("_").lower()
    return s


def infer_primary_key(columns):
    col_names = [c["name"].upper() for c in columns]
    for c in col_names:
        if c.endswith("_ID") or c == "ID":
            return c.lower()
    return col_names[0].lower() if col_names else "id"


def infer_timestamp_col(columns):
    col_names = [c["name"].upper() for c in columns]
    for pattern in ["MODIFIED_DATE", "UPDATED_AT", "MODIFIED_AT", "UPDATE_DATE",
                     "CREATED_DATE", "CREATED_AT", "LOADED_AT", "_LOADED_AT"]:
        if pattern in col_names:
            return pattern.lower()
    for c in col_names:
        if "DATE" in c or "TIMESTAMP" in c or "TIME" in c:
            return c.lower()
    return None


def classify_column(col_name, col_type):
    name_upper = col_name.upper()
    if name_upper.startswith("_") or name_upper in ("METADATA$ACTION", "METADATA$ISUPDATE", "METADATA$ROW_ID"):
        return "meta"
    if name_upper.endswith("_ID") or name_upper == "ID":
        return "key"
    if "DATE" in name_upper or "TIMESTAMP" in name_upper or "TIME" in name_upper:
        return "date"
    if "NUMBER" in col_type.upper() or "INT" in col_type.upper() or "FLOAT" in col_type.upper() or "DECIMAL" in col_type.upper():
        return "numeric"
    return "attribute"


def gen_sources_yml(tables_meta, source_name, database, schema):
    lines = [
        "version: 2",
        "",
        "sources:",
        f"  - name: {source_name}",
        f"    database: {database}",
        f"    schema: {schema}",
        f'    description: "Auto-generated source from {database}.{schema}"',
        "    tables:",
    ]
    for tbl in tables_meta:
        pk = infer_primary_key(tbl["columns"])
        lines.append(f"      - name: {tbl['name']}")
        lines.append(f'        description: "Source table {tbl["name"]}"')
        lines.append(f"        columns:")
        lines.append(f"          - name: {pk.upper()}")
        lines.append(f'            description: "Primary key"')
    return "\n".join(lines) + "\n"


def gen_staging_sql(tbl, source_name):
    tbl_name = tbl["name"]
    model_name = f"stg_{snake_case(tbl_name)}"
    columns = tbl["columns"]

    col_lines = []
    for col in columns:
        sc = snake_case(col["name"])
        original = col["name"]
        col_type = classify_column(original, col["type"])
        if col_type == "attribute" and "VARCHAR" in col["type"].upper():
            col_lines.append(f"        trim(upper({original})) as {sc}")
        elif sc != original.lower():
            col_lines.append(f"        {original} as {sc}")
        else:
            col_lines.append(f"        {sc}")

    sql = f"""with source as (
    select * from {{{{ source('{source_name}', '{tbl_name}') }}}}
),

renamed as (
    select
{chr(10).join(col_lines)}
    from source
)

select * from renamed
"""
    return model_name, sql


def gen_staging_schema_yml(staging_models):
    lines = [
        "version: 2",
        "",
        "models:",
    ]
    for model_name, tbl in staging_models:
        pk = snake_case(infer_primary_key(tbl["columns"]))
        lines.append(f"  - name: {model_name}")
        lines.append(f'    description: "Staged and cleaned {tbl["name"]}"')
        lines.append(f"    columns:")
        lines.append(f"      - name: {pk}")
        lines.append(f"        tests:")
        lines.append(f"          - not_null")
        lines.append(f"          - unique")
    return "\n".join(lines) + "\n"


def gen_intermediate_sql(tbl, stg_model_name):
    pk = snake_case(infer_primary_key(tbl["columns"]))
    ts_col = infer_timestamp_col(tbl["columns"])
    model_name = f"int_{snake_case(tbl['name'])}_deduplicated"

    order_clause = f"{ts_col} desc nulls last" if ts_col else f"{pk} desc"

    sql = f"""with source as (
    select * from {{{{ ref('{stg_model_name}') }}}}
),

deduplicated as (
    select
        *,
        row_number() over (
            partition by {pk}
            order by {order_clause}
        ) as _rn
    from source
)

select * from deduplicated where _rn = 1
"""
    return model_name, sql


def gen_intermediate_schema_yml(int_models):
    lines = [
        "version: 2",
        "",
        "models:",
    ]
    for model_name, tbl in int_models:
        pk = snake_case(infer_primary_key(tbl["columns"]))
        lines.append(f"  - name: {model_name}")
        lines.append(f'    description: "Deduplicated {tbl["name"]}"')
        lines.append(f"    columns:")
        lines.append(f"      - name: {pk}")
        lines.append(f"        tests:")
        lines.append(f"          - not_null")
        lines.append(f"          - unique")
    return "\n".join(lines) + "\n"


def classify_table_as_dim_or_fact(tbl):
    name_upper = tbl["name"].upper()
    dim_keywords = ["PATIENT", "STAFF", "FACILITY", "PROVIDER", "PHYSICIAN",
                     "LOCATION", "DEPARTMENT", "PAYER", "INSURER", "ORGANIZATION",
                     "EMPLOYEE", "USER", "CUSTOMER", "PRODUCT", "ITEM"]
    for kw in dim_keywords:
        if kw in name_upper:
            return "dim"
    return "fact"


def gen_marts_sql(tbl, int_model_name):
    pk = snake_case(infer_primary_key(tbl["columns"]))
    tbl_type = classify_table_as_dim_or_fact(tbl)
    clean_name = snake_case(tbl["name"]).replace("raw_", "")

    if tbl_type == "dim":
        model_name = f"dim_{clean_name}"
        materialized = "table"
        config_block = f"{{{{ config(materialized='{materialized}') }}}}"
    else:
        model_name = f"fact_{clean_name}"
        materialized = "incremental"
        config_block = f"""{{{{
    config(
        materialized='incremental',
        unique_key='{pk}',
        incremental_strategy='merge'
    )
}}}}"""

    columns = tbl["columns"]
    col_lines = []
    col_lines.append(f"    {{{{ hash_key_generator(['{pk}']) }}}} as pk_{clean_name}")
    for col in columns:
        sc = snake_case(col["name"])
        col_lines.append(f"    {sc}")
    col_lines.append("    current_timestamp() as _updated_at")

    incremental_filter = ""
    if materialized == "incremental":
        ts_col = infer_timestamp_col(columns)
        if ts_col:
            incremental_filter = f"""    {{% if is_incremental() %}}
    where {ts_col} > (select max({ts_col}) from {{{{ this }}}})
    {{% endif %}}"""
        else:
            incremental_filter = f"""    {{% if is_incremental() %}}
    where {pk} > (select max({pk}) from {{{{ this }}}})
    {{% endif %}}"""

    sql = f"""{config_block}

with source as (
    select * from {{{{ ref('{int_model_name}') }}}}
{incremental_filter}
)

select
{(',' + chr(10)).join(col_lines)}
from source
"""
    return model_name, sql, tbl_type


def gen_marts_schema_yml(marts_models):
    lines = [
        "version: 2",
        "",
        "models:",
    ]
    for model_name, tbl, tbl_type in marts_models:
        clean_name = snake_case(tbl["name"]).replace("raw_", "")
        pk = f"pk_{clean_name}"
        lines.append(f"  - name: {model_name}")
        lines.append(f'    description: "Mart {tbl_type} for {tbl["name"]}"')
        lines.append(f"    columns:")
        lines.append(f"      - name: {pk}")
        lines.append(f"        tests:")
        lines.append(f"          - not_null")
        lines.append(f"          - unique")
    return "\n".join(lines) + "\n"


def gen_dbt_project_yml(project_name):
    return f"""name: '{project_name}'
version: '1.0.0'
config-version: 2

profile: 'default'

model-paths: ["models"]
analysis-paths: ["analyses"]
test-paths: ["tests"]
seed-paths: ["seeds"]
macro-paths: ["macros"]
snapshot-paths: ["snapshots"]

clean-targets:
  - "target"
  - "dbt_packages"

models:
  {project_name}:
    staging:
      +schema: stg
      +tags:
        - staging
      +materialized: view
    intermediate:
      +schema: int
      +tags:
        - intermediate
      +materialized: table
    marts:
      +schema: marts
      +tags:
        - marts
      +materialized: table
      dims:
        +materialized: table
      facts:
        +materialized: incremental
        +on_schema_change: append_new_columns
"""


def gen_macros():
    hash_key = """{% macro hash_key_generator(cols = []) %}
    SHA2(
    {%- for col in cols -%}
        {{ "coalesce(cast(trim(" ~  col ~ ") as string),'') "  }}
        {%- if not loop.last -%}||'-'|| {% endif %}
    {% endfor -%}
    )
{% endmacro %}
"""
    surrogate = """{% macro surrogate_key(field_list) %}
    {{ hash_key_generator(field_list) }}
{% endmacro %}
"""
    gen_schema = """{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is not none -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}
    {%- endif -%}
{%- endmacro %}
"""
    return {"hash_key.sql": hash_key, "surrogate_key.sql": surrogate, "generate_schema_name.sql": gen_schema}


st.divider()
st.header("1. Database Explorer")

databases = get_databases()
selected_dbs = st.multiselect("Select Database(s)", databases, key="db_select")

schema_options = []
for db in selected_dbs:
    schemas = get_schemas(db)
    for s in schemas:
        schema_options.append(f"{db}.{s}")

selected_schemas = st.multiselect("Select Schema(s)", schema_options, key="schema_select")

object_options = []
for sch in selected_schemas:
    db, schema = sch.split(".", 1)
    tables = get_tables(db, schema)
    views = get_views(db, schema)
    for t in tables:
        object_options.append(f"{db}.{schema}.{t['name']} (TABLE)")
    for v in views:
        object_options.append(f"{db}.{schema}.{v['name']} (VIEW)")

selected_objects = st.multiselect("Select Tables / Views", sorted(object_options), key="obj_select")

if selected_objects:
    st.divider()
    st.header("2. Selected Objects Preview")

    tables_meta = []
    for obj in selected_objects:
        parts = obj.rsplit(" ", 1)
        fqn = parts[0]
        kind = parts[1].strip("()")
        db, schema, name = fqn.split(".", 2)
        columns = get_columns(db, schema, name)
        tables_meta.append({
            "database": db,
            "schema": schema,
            "name": name,
            "kind": kind,
            "columns": columns,
        })

    for tbl in tables_meta:
        with st.expander(f"{tbl['database']}.{tbl['schema']}.{tbl['name']} ({tbl['kind']}) — {len(tbl['columns'])} columns"):
            col_data = [{"Column": c["name"], "Type": c["type"]} for c in tbl["columns"]]
            st.dataframe(col_data, use_container_width=True)

    st.session_state.selected_tables_meta = tables_meta

if st.session_state.selected_tables_meta:
    st.divider()
    st.header("3. Generate dbt Architecture")

    col1, col2 = st.columns(2)
    with col1:
        project_name = st.text_input("dbt Project Name", value="luminary_hospice")
    with col2:
        source_name = st.text_input("Source Name (for sources.yml)", value="bronze")

    if st.button("Generate dbt Architecture", type="primary"):
        tables_meta = st.session_state.selected_tables_meta
        generated = {}

        db_groups = {}
        for tbl in tables_meta:
            key = (tbl["database"], tbl["schema"])
            if key not in db_groups:
                db_groups[key] = []
            db_groups[key].append(tbl)

        for (db, schema), tbls in db_groups.items():
            src_yml = gen_sources_yml(tbls, source_name, db, schema)
            generated["models/staging/sources.yml"] = src_yml

        staging_models = []
        for tbl in tables_meta:
            model_name, sql = gen_staging_sql(tbl, source_name)
            generated[f"models/staging/{model_name}.sql"] = sql
            staging_models.append((model_name, tbl))
        generated["models/staging/schema.yml"] = gen_staging_schema_yml(staging_models)

        int_models = []
        for stg_name, tbl in staging_models:
            model_name, sql = gen_intermediate_sql(tbl, stg_name)
            generated[f"models/intermediate/{model_name}.sql"] = sql
            int_models.append((model_name, tbl))
        generated["models/intermediate/schema.yml"] = gen_intermediate_schema_yml(int_models)

        marts_dims = []
        marts_facts = []
        for int_name, tbl in int_models:
            model_name, sql, tbl_type = gen_marts_sql(tbl, int_name)
            if tbl_type == "dim":
                generated[f"models/marts/dims/{model_name}.sql"] = sql
                marts_dims.append((model_name, tbl, tbl_type))
            else:
                generated[f"models/marts/facts/{model_name}.sql"] = sql
                marts_facts.append((model_name, tbl, tbl_type))

        all_marts = marts_dims + marts_facts
        generated["models/marts/dims/schema.yml"] = gen_marts_schema_yml(marts_dims) if marts_dims else ""
        generated["models/marts/facts/schema.yml"] = gen_marts_schema_yml(marts_facts) if marts_facts else ""

        generated["dbt_project.yml"] = gen_dbt_project_yml(project_name)

        macros = gen_macros()
        for fname, content in macros.items():
            generated[f"macros/{fname}"] = content

        st.session_state.generated_code = generated
        st.success(f"Generated {len(generated)} files across the full medallion architecture!")

if st.session_state.generated_code:
    st.divider()
    st.header("4. Generated dbt Architecture")

    generated = st.session_state.generated_code

    layer_order = ["dbt_project.yml", "models/staging/sources.yml"]
    staging = sorted([k for k in generated if k.startswith("models/staging/") and k not in layer_order])
    intermediate = sorted([k for k in generated if k.startswith("models/intermediate/")])
    marts = sorted([k for k in generated if k.startswith("models/marts/")])
    macros = sorted([k for k in generated if k.startswith("macros/")])

    tab_stg, tab_int, tab_marts, tab_cfg = st.tabs(["Staging", "Intermediate", "Marts", "Config & Macros"])

    with tab_stg:
        st.subheader("Sources")
        if "models/staging/sources.yml" in generated:
            st.code(generated["models/staging/sources.yml"], language="yaml")
        st.subheader("Staging Models")
        for f in staging:
            lang = "yaml" if f.endswith(".yml") else "sql"
            with st.expander(f):
                st.code(generated[f], language=lang)

    with tab_int:
        st.subheader("Intermediate Models")
        for f in intermediate:
            lang = "yaml" if f.endswith(".yml") else "sql"
            with st.expander(f):
                st.code(generated[f], language=lang)

    with tab_marts:
        st.subheader("Marts — Dims & Facts")
        for f in marts:
            lang = "yaml" if f.endswith(".yml") else "sql"
            with st.expander(f):
                st.code(generated[f], language=lang)

    with tab_cfg:
        st.subheader("dbt_project.yml")
        st.code(generated.get("dbt_project.yml", ""), language="yaml")
        st.subheader("Macros")
        for f in macros:
            with st.expander(f):
                st.code(generated[f], language="sql")

    st.divider()
    st.subheader("Architecture Summary")
    stg_count = len([k for k in generated if k.startswith("models/staging/") and k.endswith(".sql")])
    int_count = len([k for k in generated if k.startswith("models/intermediate/") and k.endswith(".sql")])
    dim_count = len([k for k in generated if k.startswith("models/marts/dims/") and k.endswith(".sql")])
    fact_count = len([k for k in generated if k.startswith("models/marts/facts/") and k.endswith(".sql")])

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Staging Models", stg_count)
    c2.metric("Intermediate Models", int_count)
    c3.metric("Dimension Models", dim_count)
    c4.metric("Fact Models", fact_count)

    st.markdown(f"""
| Layer | Schema | Materialization | Count |
|-------|--------|-----------------|-------|
| Staging | `stg` | view | {stg_count} |
| Intermediate | `int` | table | {int_count} |
| Marts — Dims | `marts` | table | {dim_count} |
| Marts — Facts | `marts` | incremental (merge) | {fact_count} |
""")
