defmodule FarmbotExt.API.DirtyWorker.Supervisor do
  @moduledoc """
  Responsible for supervising assets that will need to be 
  uploaded to the API via a `POST` or `PUT` request. 
  """

  # What does this do?
  use Supervisor
  alias FarmbotExt.API.DirtyWorker

  alias FarmbotCore.Asset.{
    Device,
    DeviceCert,
    DiagnosticDump,
    FarmEvent,
    FarmwareEnv,
    FarmwareInstallation,
    FbosConfig,
    FirmwareConfig,
    Peripheral,
    PinBinding,
    Point,
    PointGroup,
    Regimen,
    SensorReading,
    Sensor,
    Sequence,
    Tool
  }

  @doc false
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      {DirtyWorker, Device},
      {DirtyWorker, DeviceCert},
      {DirtyWorker, FbosConfig},
      {DirtyWorker, FirmwareConfig},
      {DirtyWorker, DiagnosticDump},
      {DirtyWorker, FarmEvent},
      {DirtyWorker, FarmwareEnv},
      {DirtyWorker, FarmwareInstallation},
      {DirtyWorker, Peripheral},
      {DirtyWorker, PinBinding},
      {DirtyWorker, Point},
      {DirtyWorker, PointGroup},
      {DirtyWorker, Regimen},
      {DirtyWorker, SensorReading},
      {DirtyWorker, Sensor},
      {DirtyWorker, Sequence},
      {DirtyWorker, Tool}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
