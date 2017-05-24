defmodule Farmbot.Farmware.Installer do
  @moduledoc """
    Handles the installing and uninstalling of packages
  """

  alias Farmbot.{Context, Farmware, System}
  alias Farmware.Manager
  alias Farmware.Installer.Repository
  alias System.FS
  use Farmbot.DebugLog
  @version Mix.Project.config[:version]

  @doc """
    Installs a farmware.
    Does not register to the Manager.
  """
  @spec install!(Context.t, binary) :: Farmware.t | no_return
  def install!(%Context{} = ctx, url) do
    :ok    = ensure_dirs!()
    schema = ensure_schema!()
    binary = Farmbot.HTTP.get!(ctx, url)
    json   = Poison.decode!(binary)
    :ok    = validate_json!(schema, json)
    debug_log "Installing a Farmware from: #{url}"
    print_json_debug_info(json)
    ensure_correct_version!(json)
    dl_path      = Farmbot.HTTP.download_file!(ctx, json["zip"])
    package_path = "#{package_path()}/#{json["package"]}"
    FS.transaction fn() ->
      unzip! dl_path, package_path
    end, true
    Farmware.new(json)
  end

  defp ensure_correct_version!(%{"min_os_version_major" => major}) do
    ver_int = @version |> String.first() |> String.to_integer
    if major != ver_int do
       raise "Version mismatch! Farmbot is: #{ver_int} Farmware requires: #{major}"
     else
       :ok
    end
  end

  defp print_json_debug_info(json) do
    json
    |> Enum.reduce("", fn({key, val}, acc) ->
        " #{key} => #{inspect val}\n" <> acc
       end)
    |> debug_log
  end

  @doc """
    Uninstalls a farmware.
    Does no unregister from the Manager.
  """
  @spec uninstall!(Context.t, Farmware.t) :: :ok | no_return
  def uninstall!(%Context{} = _ctx, %Farmware{} = fw) do
    :ok    = ensure_dirs!()
    debug_log "Uninstalling a Farmware from: #{inspect fw}"
    package_path = "#{package_path()}/#{fw.name}"
    FS.transaction fn() ->
      File.rm_rf!(package_path)
    end, true
  end

  @doc """
    Enables a repo to be synced on bootup
  """
  @spec enable_repo!(Context.t, atom) :: :ok | no_return
  def enable_repo!(%Context{} = ctx, module) when is_atom(module) do
    debug_log "Syncing repo: #{module}"
    # make sure we have a valid repository here.
    ensure_module!(module)
    :ok        = ensure_dirs!()
    binary     = Farmbot.HTTP.get!(ctx, module.url())
    json       = Poison.decode!(binary)
    repository = Repository.validate!(json)

    :ok = ensure_not_synced!(module)
    # do the installs
    for entry <- repository.entries do
      :ok = Manager.install(ctx, entry.manifest)
    end

    set_synced!(module)
  end

  defp ensure_dirs! do
    ensure_dir! path()
    ensure_dir! repo_path()
    ensure_dir! package_path()
  end

  defp ensure_dir!(path) do
    unless File.exists?(path) do
      FS.transaction fn() ->
        File.mkdir_p!(path)
      end
    end
  end

  defp ensure_not_synced!(module) when is_atom(module) do
    path = "#{repo_path()}/#{module}"
    if File.exists?(path) do
      raise "Could not sync #{module} is already synced up!"
    else
      :ok
    end
  end

  defp set_synced!(module) when is_atom(module) do
     path = "#{repo_path()}/#{module}"
     FS.transaction fn() ->
       File.write! path, "#{:os.system_time}"
     end, true
     debug_log "#{module} was synced"
     :ok
  end

  defp ensure_module!(module) do
    unless function_exported?(module, :url, 0) do
      raise "Could not load repository: #{inspect module}"
    end
  end

  defp path, do: "#{FS.path()}/farmware"
  defp repo_path, do: "#{path()}/repos"
  defp package_path, do: "#{path()}/packages"

  defp unzip!(zip_file, path) when is_bitstring(zip_file) do
    cwd = File.cwd!
    File.cd! path
    :zip.unzip(String.to_charlist(zip_file))
    File.cd! cwd
  end

  @doc """
    Ensures the schema has been resolved.
  """
  def ensure_schema! do
    schema_path() |> File.read!() |> Poison.decode!() |> ExJsonSchema.Schema.resolve()
  end

  defp schema_path, do: "#{:code.priv_dir(:farmbot)}/static/farmware_schema.json"

  defp validate_json!(schema, json) do
    case ExJsonSchema.Validator.validate(schema, json) do
      :ok              -> :ok
      {:error, reason} ->  raise "Error parsing manifest #{inspect reason}"
    end
  end

end
